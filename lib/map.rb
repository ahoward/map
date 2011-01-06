class Map < Hash
  Version = '2.1.0' unless defined?(Version)
  Load = Kernel.method(:load) unless defined?(Load)

  class << Map
    def version
      Map::Version
    end

    def libdir(*args, &block)
      @libdir ||= File.expand_path(__FILE__).sub(/\.rb$/,'')
      libdir = args.empty? ? @libdir : File.join(@libdir, *args.map{|arg| arg.to_s})
    ensure
      if block
        begin
          $LOAD_PATH.unshift(libdir) unless $LOAD_PATH.first==libdir
          module_eval(&block)
        ensure
          $LOAD_PATH.shift() if $LOAD_PATH.first==libdir
        end
      end
    end

    def load(*args, &block)
      libdir{ Load.call(*args, &block) }
    end

    def allocate
      super.instance_eval do
        @keys = []
        self
      end
    end

    def new(*args, &block)
      allocate.instance_eval do
        initialize(*args, &block)
        self
      end
    end

    def for(*args, &block)
      if(args.size == 1 and block.nil?)
        return args.first if args.first.class == self
      end
      new(*args, &block)
    end

    def coerce(other)
      return other if other.class == self
      allocate.update(other.to_hash)
    end

    def conversion_methods
      @conversion_methods ||= (
        map_like = ancestors.select{|ancestor| ancestor <= Map}
        type_names = map_like.map do |ancestor|
          name = ancestor.name.to_s.strip
          next if name.empty?
          name.downcase.gsub(/::/, '_')
        end.compact
        type_names.map{|type_name| "to_#{ type_name }"}
      )
    end

    def add_conversion_method!(method)
      method = method.to_s.strip
      raise ArguementError if method.empty?
      module_eval(<<-__, __FILE__, __LINE__)
        unless public_method_defined?(#{ method.inspect })
          def #{ method }
            self
          end
        end
        unless conversion_methods.include?(#{ method.inspect })
          conversion_methods.unshift(#{ method.inspect })
        end
      __
    end

    def inherited(other)
      other.module_eval(&Dynamic)
      super
    end

  # iterate over arguments in pairs smartly.
  #
    def each_pair(*args)
      size = args.size
      parity = size % 2 == 0 ? :even : :odd
      first = args.first

      return args if size == 0

      if size == 1 and first.respond_to?(:each_pair)
        first.each_pair do |key, val|
          yield(key, val)
        end
        return args
      end

      if size == 1 and first.respond_to?(:each_slice)
        first.each_slice(2) do |key, val|
          yield(key, val)
        end
        return args
      end

      array_of_pairs = args.all?{|a| a.is_a?(Array) and a.size == 2}

      if array_of_pairs
        args.each do |pair|
          key, val, *ignored = pair
          yield(key, val)
        end
      else
        0.step(args.size - 1, 2) do |a|
          key = args[a]
          val = args[a + 1]
          yield(key, val)
        end
      end

      args
    end

    alias_method '[]', 'new'
  end

  Dynamic = lambda do
    conversion_methods.reverse_each do |method|
      add_conversion_method!(method)
    end
  end
  module_eval(&Dynamic)


# instance constructor 
#
  def keys
    @keys ||= []
  end

  def initialize(*args, &block)
    case args.size
      when 0
        super(&block)

      when 1
        case args.first
          when Hash
            initialize_from_hash(args.first)
          when Array
            initialize_from_array(args.first)
          else
            initialize_from_hash(args.first.to_hash)
        end

      else
        initialize_from_array(args)
    end
  end

  def initialize_from_hash(hash)
    map = self
    map.update(hash)
    map.default = hash.default
  end

  def initialize_from_array(array)
    map = self
    Map.each_pair(array){|key, val| map[key] = val}
  end

# support methods
#
  def klass
    self.class
  end

  def map_for(hash)
    map = klass.coerce(hash)
    map.default = hash.default
    map
  end

  def convert_key(key)
    key.kind_of?(Symbol) ? key.to_s : key
  end

  def convert_value(value)
    conversion_methods.each do |method|
      return value.send(method) if value.respond_to?(method)
    end

    case value
      when Hash
        klass.coerce(value)
      when Array
        value.map{|v| convert_value(v)}
      else
        value
    end
  end
  alias_method('convert_val', 'convert_value')

  def convert(key, val)
    [convert_key(key), convert_value(val)]
  end

# maps are aggressive with copy operations.  they are all deep copies.  make a
# new one if you really want a shallow copy
#
  def copy
    default = self.default
    self.default = nil
    copy = Marshal.load(Marshal.dump(self))
    copy.default = default
    copy
  ensure
    self.default = default
  end

  def dup
    copy
  end

  def clone
    copy
  end

  def default(key = nil)
    key.is_a?(Symbol) && include?(key = key.to_s) ? self[key] : super
  end

# writer/reader methods
#
  alias_method '__set__', '[]=' unless method_defined?('__set__')
  alias_method '__get__', '[]' unless method_defined?('__get__')
  alias_method '__update__', 'update' unless method_defined?('__update__')

  def []=(key, val)
    key, val = convert(key, val)
    keys.push(key) unless has_key?(key)
    __set__(key, val)
  end
  alias_method 'store', '[]='

  def [](key)
    __get__(convert_key(key))
  end

  def fetch(key, *args, &block)
    super(convert_key(key), *args, &block)
  end

  def key?(key)
    super(convert_key(key))
  end
  alias_method 'include?', 'key?'
  alias_method 'has_key?', 'key?'
  alias_method 'member?', 'key?'

  def update(*args)
    Map.each_pair(*args){|key, val| store(key, val)}
    self
  end
  alias_method 'merge!', 'update'

  def merge(*args)
    copy.update(*args)
  end

  def reverse_merge(hash)
    map = copy
    hash.each{|key, val| map[key] = val unless map.key?(key)}
    map
  end

  def reverse_merge!(hash)
    replace(reverse_merge(hash))
  end

  def values
    array = []
    keys.each{|key| array.push(self[key])}
    array
  end
  alias_method 'vals', 'values'

  def values_at(*keys)
    keys.map{|key| self[key]}
  end

  def first
    [keys.first, self[keys.first]]
  end

  def last
    [keys.last, self[keys.last]]
  end

# iterator methods
#
  def each_with_index
    keys.each_with_index{|key, index| yield([key, self[key]], index)}
    self
  end

  def each_key
    keys.each{|key| yield(key)}
    self
  end

  def each_value
    keys.each{|key| yield self[key]}
    self
  end

  def each
    keys.each{|key| yield(key, self[key])}
    self
  end
  alias_method 'each_pair', 'each'

# mutators
#
  def delete(key)
    key = convert_key(key)
    keys.delete(key)
    super(key)
  end

  def clear
    keys.clear
    super
  end

  def delete_if
    to_delete = []
    keys.each{|key| to_delete.push(key) if yield(key)}
    to_delete.each{|key| delete(key)}
    self
  end

  def replace(hash)
    clear
    update(hash)
  end

# ordered container specific methods
#
  def shift
    unless empty?
      key = keys.first
      val = delete(key)
      [key, val]
    end
  end

  def unshift(*args)
    Map.each_pair(*args) do |key, val|
      if key?(key)
        delete(key)
      else
        keys.unshift(key)
      end
      __set__(key, val)
    end
    self
  end

  def push(*args)
    Map.each_pair(*args) do |key, val|
      if key?(key)
        delete(key)
      else
        keys.push(key)
      end
      __set__(key, val)
    end
    self
  end

  def pop
    unless empty?
      key = keys.last
      val = delete(key)
      [key, val]
    end
  end

# misc
#
  def ==(hash)
    return false unless(Map === hash)
    return false if keys != hash.keys
    super hash
  end

  def <=>(other)
    keys <=> klass.coerce(other).keys
  end

  def =~(hash)
    to_hash == klass.coerce(hash).to_hash
  end

  def invert
    inverted = klass.allocate
    inverted.default = self.default
    keys.each{|key| inverted[self[key]] = key }
    inverted
  end

  def reject(&block)
    dup.delete_if(&block)
  end

  def reject!(&block)
    hash = reject(&block)
    self == hash ? nil : hash
  end

  def select
    array = []
    each{|key, val| array << [key,val] if yield(key, val)}
    array
  end

  def inspect
    array = []
    each{|key, val| array << (key.inspect + "=>" + val.inspect)}
    string = '{' + array.join(", ") + '}'
  end

# conversions
#
  def conversion_methods
    self.class.conversion_methods
  end

  conversion_methods.each do |method|
    module_eval(<<-__, __FILE__, __LINE__)
      def #{ method }
        self
      end
    __
  end

  def to_hash
    hash = Hash.new(default)
    each do |key, val|
      val = val.to_hash if val.respond_to?(:to_hash)
      hash[key] = val
    end
    hash
  end

  def as_hash
    @class = Hash
    yield
  ensure
    @class = nil
  end

  def class
    @class || super
  end

  def to_yaml(*args, &block)
    as_hash{ super }
  end

  def to_array
    array = []
    each{|*pair| array.push(pair)}
    array
  end
  alias_method 'to_a', 'to_array'

  def to_list
    list = []
    each_pair do |key, val|
      list[key.to_i] = val if(key.is_a?(Numeric) or key.to_s =~ %r/^\d+$/)
    end
    list
  end

  def to_s
    to_array.to_s
  end

# oh rails - would that map.rb existed before all this non-sense...
#
  def stringify_keys!; self end
  def stringify_keys; dup end
  def symbolize_keys!; self end
  def symbolize_keys; dup end
  def to_options!; self end
  def to_options; dup end
  def with_indifferent_access!; self end
  def with_indifferent_access; dup end

# a sane method missing that only supports writing values or reading
# *previously set* values
#
  def method_missing(method, *args, &block)
    method = method.to_s
    case method
      when /=$/
        key = method.chomp('=')
        value = args.shift
        self[key] = value
      else
        key = method
        super unless has_key?(key)
        self[key]
    end
  end

  def id
    raise NoMethodError unless has_key?(:id)
    self[:id]
  end

# support for compound key indexing and depth first iteration
#
  def get(*keys)
    keys = keys.flatten
    return self[keys.first] if keys.size <= 1
    keys, key = keys[0..-2], keys[-1]
    collection = self
    keys.each do |k|
      k = alphanumeric_key_for(k)
      collection = collection[k]
      return collection unless collection.respond_to?('[]')
    end
    collection[alphanumeric_key_for(key)]
  end

  def has?(*keys)
    keys = keys.flatten
    collection = self
    return collection_has_key?(collection, keys.first) if keys.size <= 1
    keys, key = keys[0..-2], keys[-1]
    keys.each do |k|
      k = alphanumeric_key_for(k)
      collection = collection[k]
      return collection unless collection.respond_to?('[]')
    end
    return false unless(collection.is_a?(Hash) or collection.is_a?(Array))
    collection_has_key?(collection, alphanumeric_key_for(key))
  end

  def collection_has_key?(collection, key)
    case collection
      when Hash
        collection.has_key?(key)
      when Array
        return false unless key
        (0...collection.size).include?(Integer(key))
    end
  end

  def set(*args)
    if args.size == 1 and args.first.is_a?(Hash)
      options = args.shift
    else
      options = {}
      value = args.pop
      keys = args
      options[keys] = value
    end

    options.each do |keys, value|
      keys = Array(keys).flatten

      collection = self
      if keys.size <= 1
        collection[keys.first] = value
        next
      end

      key = nil

      keys.each_cons(2) do |a, b|
        a, b = alphanumeric_key_for(a), alphanumeric_key_for(b)

        case b
          when Numeric
            collection[a] ||= []
            raise(IndexError, "(#{ collection.inspect })[#{ a.inspect }]=#{ value.inspect }") unless collection[a].is_a?(Array)

          when String, Symbol
            collection[a] ||= {}
            raise(IndexError, "(#{ collection.inspect })[#{ a.inspect }]=#{ value.inspect }") unless collection[a].is_a?(Hash)
        end
        collection = collection[a]
        key = b
      end

      collection[key] = value
    end

    return options.values
  end

  def Map.alphanumeric_key_for(key)
    return key if Numeric===key
    key.to_s =~ %r/^\d+$/ ? Integer(key) : key
  end

  def alphanumeric_key_for(key)
    Map.alphanumeric_key_for(key)
  end

  def Map.depth_first_each(enumerable, path = [], accum = [], &block)
    Map.pairs_for(enumerable) do |key, val|
      path.push(key)
      if((val.is_a?(Hash) or val.is_a?(Array)) and not val.empty?)
        Map.depth_first_each(val, path, accum)
      else
        accum << [path.dup, val]
      end
      path.pop()
    end
    if block
      accum.each{|keys, val| block.call(keys, val)}
    else
      [path, accum]
    end
  end

  def Map.pairs_for(enumerable, *args, &block)
    if block.nil?
      pairs, block = [], lambda{|*pair| pairs.push(pair)}
    else
      pairs = false
    end

    result =
      case enumerable
        when Hash
          enumerable.each_pair(*args, &block)
        when Array
          enumerable.each_with_index(*args) do |val, key|
            block.call(key, val)
          end
        else
          enumerable.each_pair(*args, &block)
      end

    pairs ? pairs : result
  end

  def depth_first_each(*args, &block)
    Map.depth_first_each(enumerable=self, *args, &block)
  end
end

module Kernel
private
  def Map(*args, &block)
    Map.new(*args, &block)
  end
end

Map.load('struct.rb')
Map.load('options.rb')

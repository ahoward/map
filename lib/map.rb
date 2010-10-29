class Map < Hash
  Version = '1.5.1' unless defined?(Version)
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
      first = args.first
      if(args.size == 1 and block.nil?)
        return first.to_map if first.respond_to?(:to_map)
      end
      new(*args, &block)
    end

    def coerce(other)
      return other.to_map if other.respond_to?(:to_map)
      allocate.update(other.to_hash)
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
    return value.to_map if value.respond_to?(:to_map)
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

# converions
#
  def to_map
    self
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

  def to_s
    to_array.to_s
  end

  def stringify_keys!; self end
  def stringify_keys; dup end
  def symbolize_keys!; self end
  def symbolize_keys; dup end
  def to_options!; self end
  def to_options; dup end
  def with_indifferent_access!; self end
  def with_indifferent_access; dup end
end

module Kernel
private
  def Map(*args, &block)
    Map.new(*args, &block)
  end
end

Map.load('struct.rb')
Map.load('options.rb')

class Map < Hash
  Version = '4.3.0' unless defined?(Version)
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
      case other
        when Map
          other
        else
          allocate.update(other.to_hash)
      end
    end

    def conversion_methods
      @conversion_methods ||= (
        map_like = ancestors.select{|ancestor| ancestor <= Map}
        type_names = map_like.map do |ancestor|
          name = ancestor.name.to_s.strip
          next if name.empty?
          name.downcase.gsub(/::/, '_')
        end.compact
        list = type_names.map{|type_name| "to_#{ type_name }"}
        list.each{|method| define_conversion_method!(method)}
        list
      )
    end

    def define_conversion_method!(method)
      method = method.to_s.strip
      raise ArguementError if method.empty?
      module_eval(<<-__, __FILE__, __LINE__)
        unless public_method_defined?(#{ method.inspect })
          def #{ method }
            self
          end
          true
        else
          false
        end
      __
    end

    def add_conversion_method!(method)
      if define_conversion_method!(method)
        method = method.to_s.strip
        raise ArguementError if method.empty?
        module_eval(<<-__, __FILE__, __LINE__)
          unless conversion_methods.include?(#{ method.inspect })
            conversion_methods.unshift(#{ method.inspect })
          end
        __
        true
      else
        false
      end
    end

  # iterate over arguments in pairs smartly.
  #
    def each_pair(*args, &block)
      size = args.size
      parity = size % 2 == 0 ? :even : :odd
      first = args.first

      if block.nil?
        result = []
        block = lambda{|*kv| result.push(kv)}
      else
        result = args
      end

      return args if size == 0

      if size == 1
        conversion_methods.each do |method|
          if first.respond_to?(method)
            first = first.send(method)
            break
          end
        end

        if first.respond_to?(:each_pair)
          first.each_pair do |key, val|
            block.call(key, val)
          end
          return args
        end

        if first.respond_to?(:each_slice)
          first.each_slice(2) do |key, val|
            block.call(key, val)
          end
          return args
        end

        raise(ArgumentError, 'odd number of arguments for Map')
      end

      array_of_pairs = args.all?{|a| a.is_a?(Array) and a.size == 2}

      if array_of_pairs
        args.each do |pair|
          key, val, *ignored = pair
          block.call(key, val)
        end
      else
        0.step(args.size - 1, 2) do |a|
          key = args[a]
          val = args[a + 1]
          block.call(key, val)
        end
      end

      args
    end
    alias_method '[]', 'new'

    def intersection(a, b)
      a, b, i = Map.for(a), Map.for(b), Map.new
      a.depth_first_each{|key, val| i.set(key, val) if b.has?(key)}
      i
    end

    def match(haystack, needle)
      intersection(haystack, needle) == needle
    end
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
        first = args.first
        case first
          when nil, false
            nil
          when Hash
            initialize_from_hash(first)
          when Array
            initialize_from_array(first)
          else
            if first.respond_to?(:to_hash)
              initialize_from_hash(first.to_hash)
            else
              initialize_from_hash(first)
            end
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

  def Map.map_for(hash)
    map = klass.coerce(hash)
    map.default = hash.default
    map
  end
  def map_for(hash)
    klass.map_for(hash)
  end

=begin
  def self.convert_key(key)
    key.kind_of?(Symbol) ? key.to_s : key
  end
=end

  def self.convert_key(key)
    key = key.kind_of?(Symbol) ? key.to_s : key
  end

  def convert_key(key)
    if klass.respond_to?(:convert_key)
      klass.convert_key(key)
    else
      Map.convert_key(key)
    end
  end

  def self.convert_value(value)
    conversion_methods.each do |method|
      #return convert_value(value.send(method)) if value.respond_to?(method)
      hashlike = value.is_a?(Hash)
      if hashlike and value.respond_to?(method)
        value = value.send(method)
        break
      end
    end

    case value
      when Hash
        coerce(value)
      when Array
        value.map{|v| convert_value(v)}
      else
        value
    end
  end
  def convert_value(value)
    if klass.respond_to?(:convert_value)
      klass.convert_value(value)
    else
      Map.convert_value(value)
    end
  end
  alias_method('convert_val', 'convert_value')

  def convert(key, val)
    [convert_key(key), convert_value(val)]
  end

# maps are aggressive with copy operations.  they are all deep copies.  make a
# new one if you really want a shallow copy
#
# TODO - fallback to shallow if objects cannot be marshal'd....
  def copy
    default = self.default
    self.default = nil
    copy = Marshal.load(Marshal.dump(self)) rescue Dup.bind(self).call()
    copy.default = default
    copy
  ensure
    self.default = default
  end

  Dup = instance_method(:dup) unless defined?(Dup)

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
    key = convert_key(key)
    __get__(key)
  end

  def fetch(key, *args, &block)
    key = convert_key(key)
    super(key, *args, &block)
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

  def replace(*args)
    clear
    update(*args)
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

# equality / sorting / matching support 
#
  def ==(other)
    case other
      when Map
        return false if keys != other.keys
        super(other)

      when Hash
        self == Map.from_hash(other, self)

      else
        false
    end
  end

  def <=>(other)
    cmp = keys <=> klass.coerce(other).keys
    return cmp unless cmp.zero?
    values <=> klass.coerce(other).values
  end

  def =~(hash)
    to_hash == klass.coerce(hash).to_hash
  end

# reordering support
#
  def reorder(order = {})
    order = Map.for(order)
    map = Map.new
    keys = order.depth_first_keys | depth_first_keys
    keys.each{|key| map.set(key, get(key))}
    map
  end

  def reorder!(order = {})
    replace(reorder(order))
  end

# support for building ordered hasshes from a map's own image
#
  def Map.from_hash(hash, order = nil)
    map = Map.for(hash)
    map.reorder!(order) if order
    map
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

  def inspect(*args, &block)
    require 'pp' unless defined?(PP)
    PP.pp(self, '')
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

  def to_yaml( opts = {} )
    map = self
    YAML.quick_emit(self.object_id, opts){|out|
      out.map('!omap'){|m| map.each{|k,v| m.add(k, v)}}
    }
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
  def method_missing(*args, &block)
    method = args.first.to_s
    case method
      when /=$/
        key = args.shift.to_s.chomp('=')
        value = args.shift
        self[key] = value
      else
        key = method
        unless has_key?(key)
          return(block ? fetch(*args, &block) : super(*args))
        end
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
    keys = key_for(keys)
    if keys.size <= 1
      if !self.has_key?(keys.first) && block_given?
        return yield
      else
        return self[keys.first] 
      end
    end
    keys, key = keys[0..-2], keys[-1]
    collection = self
    keys.each do |k|
      k = alphanumeric_key_for(k)
      collection = collection[k]
      return collection unless collection.respond_to?('[]')
    end
    alphanumeric_key = alphanumeric_key_for(key)

    if !collection_has_key?(collection, alphanumeric_key) && block_given?
      yield
    else
      collection[alphanumeric_key]
    end
  end

  def has?(*keys)
    keys = key_for(keys)
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

  def blank?(*keys)
    return empty? if keys.empty?
    !has?(*keys) or Map.blank?(get(*keys))
  end

  def Map.blank?(value)
    return value.blank? if value.respond_to?(:blank?)

    case value
      when String
        value.strip.empty?
      when Numeric
        value == 0
      when false
        true
      else
        value.respond_to?(:empty?) ? value.empty? : !value
    end
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
      spec = args.shift
    else
      spec = {}
      value = args.pop
      keys = args
      spec[keys] = value
    end

    spec.each do |keys, value|
      keys = Array(keys).flatten

      collection = self

      keys = key_for(keys)

      if keys.size <= 1
        key = keys.first
        collection[key] = value
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

    return spec.values
  end

  def rm(*args)
    paths, path = args.partition{|arg| arg.is_a?(Array)}
    paths.push(path)

    paths.each do |path|
      if path.size == 1
        delete(*path)
        next
      end

      branch, leaf = path[0..-2], path[-1]
      collection = get(branch)

      case collection
        when Hash
          key = leaf
          collection.delete(key)
        when Array
          index = leaf
          collection.delete_at(index)
        else
          raise(IndexError, "(#{ collection.inspect }).rm(#{ path.inspect })")
      end
    end
    paths
  end

  def forcing(forcing=nil, &block)
    @forcing ||= nil

    if block
      begin
        previous = @forcing
        @forcing = forcing
        block.call()
      ensure
        @forcing = previous
      end
    else
      @forcing
    end
  end

  def forcing?(forcing=nil)
    @forcing ||= nil
    @forcing == forcing
  end

  def apply(other)
    Map.for(other).depth_first_each do |keys, value|
      set(keys => value) unless !get(keys).nil?
    end
    self
  end

  def Map.alphanumeric_key_for(key)
    return key if Numeric===key
    key.to_s =~ %r/^\d+$/ ? Integer(key) : key
  end

  def alphanumeric_key_for(key)
    Map.alphanumeric_key_for(key)
  end

## key path support
#
  def self.dot_key_for(*keys)
    dot = keys.compact.flatten.join('.')
    dot.split(%r/\s*[,.:_-]\s*/).map{|part| part =~ %r/^\d+$/ ? Integer(part) : part}
  end

  def self.dot_keys
    @@dot_keys = {} unless defined?(@@dot_keys)
    @@dot_keys
  end

  def self.dot_keys?
    ancestors.each do |ancestor|
      return dot_keys[ancestor] if dot_keys.has_key?(ancestor)
    end
    false
  end

  def dot_keys?
    @dot_keys = false unless defined?(@dot_keys)
    @dot_keys
  end

  def self.dot_keys!(boolean = true)
    dot_keys[self] = !!boolean
  end

  def dot_keys!(boolean = true)
    @dot_keys = !!boolean
  end

  def self.key_for(*keys)
    return keys.flatten unless dot_keys?
    self.dot_key_for(*keys)
  end

  def key_for(*keys)
    if dot_keys?
      self.class.dot_key_for(*keys)
    else
      self.class.key_for(*keys)
    end
  end

## TODO - technically this returns only leaves so the name isn't *quite* right.  re-factor for 3.0
#
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
      accum
    end
  end

  def Map.depth_first_keys(enumerable, path = [], accum = [], &block)
    accum = Map.depth_first_each(enumerable, path = [], accum = [], &block)
    accum.map!{|kv| kv.first}
    accum
  end

  def Map.depth_first_values(enumerable, path = [], accum = [], &block)
    accum = Map.depth_first_each(enumerable, path = [], accum = [], &block)
    accum.map!{|kv| kv.last}
    accum
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

  def Map.breadth_first_each(enumerable, accum = [], &block)
    levels = []

    keys = Map.depth_first_keys(enumerable)

    keys.each do |key|
      key.size.times do |i|
        k = key.slice(0, i + 1)
        level = k.size - 1
        levels[level] ||= Array.new
        last = levels[level].last
        levels[level].push(k) unless last == k
      end
    end

    levels.each do |level|
      level.each do |key|
        val = enumerable.get(key)
        block ? block.call(key, val) : accum.push([key, val])
      end
    end

    block ? enumerable : accum
  end

  def Map.keys_for(enumerable)
    keys = enumerable.respond_to?(:keys) ? enumerable.keys : Array.new(enumerable.size){|i| i}
  end

  def depth_first_each(*args, &block)
    Map.depth_first_each(enumerable=self, *args, &block)
  end

  def depth_first_keys(*args, &block)
    Map.depth_first_keys(enumerable=self, *args, &block)
  end

  def depth_first_values(*args, &block)
    Map.depth_first_values(enumerable=self, *args, &block)
  end

  def breadth_first_each(*args, &block)
    Map.breadth_first_each(enumerable=self, *args, &block)
  end

  def contains(other)
    other = other.is_a?(Hash) ? Map.coerce(other) : other
    breadth_first_each{|key, value| return true if value == other}
    return false
  end
  alias_method 'contains?', 'contains'

## for rails' extract_options! compat
#
  def extractable_options?
    true
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

class Map < Hash
  Version = '1.0.0' unless defined?(Version)
  Load = Kernel.method(:load) unless defined?(Load)

  class << Map
    def version
      Map::Version
    end

  # class constructor 
  #
    def new(*args, &block)
      case args.size
        when 0
          super(&block)

        when 1
          case args.first
            when Hash
              new_from_hash(args.first)
            when Array
              new_from_array(args.first)
            else
              new_from_hash(args.first.to_hash)
          end

        else
          new_from_array(args)
      end
    end

    def new_from_hash(hash)
      map = new
      map.update(hash)
      map
    end

    def new_from_array(array)
      map = new
      each_pair(array){|key, val| map[key] = val}
      map
    end

    def for(*args, &block)
      first = args.first

      if(args.size == 1 and block.nil?)
        return first.to_map if first.respond_to?(:to_map)
      end

      new(*args, &block)
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
  attr_accessor :keys

  def initialize(*args, &block)
    super
    @keys = []
  end

# support methods
#
  def map
    self
  end

  def map_for(hash)
    map = Map.new(hash)
    map.default = hash.default
    map
  end

  def convert_key(key)
    key.kind_of?(Symbol) ? key.to_s : key
  end

  def convert_val(val)
    case val
      when Hash
        map_for(val)
      when Array
        val.collect{|v| Hash === v ? map_for(v) : v}
      else
        val
    end
  end

  def convert(key, val)
    [convert_key(key), convert_val(val)]
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

  def set(key, val)
    key, val = convert(key, val)
    @keys.push(key) unless has_key?(key)
    __set__(key, val)
  end
  alias_method 'store', 'set'
  alias_method '[]=', 'set'

  def get(key)
    __get__(key)
  end
  alias_method '[]', 'get'

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
    Map.each_pair(*args) do |key, val|
      set(key, val)
    end
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
    @keys.each{|key| array.push(self[key])}
    array
  end
  alias_method 'vals', 'values'

  def values_at(*keys)
    keys.map{|key| self[key]}
  end

  def first
    [@keys.first, self[@keys.first]]
  end

  def last
    [@keys.last, self[@keys.last]]
  end

# iterator methods
#
  def each_with_index
    @keys.each_with_index{|key, index| yield([key, self[key]], index)}
    self
  end

  def each_key
    @keys.each{|key| yield(key)}
    self
  end

  def each_value
    @keys.each{|key| yield self[key]}
    self
  end

  def each
    @keys.each{|key| yield(key, self[key])}
    self
  end
  alias_method 'each_pair', 'each'

# mutators
#
  def delete(key)
    key = convert_key(key)
    @keys.delete(key)
    super(key)
  end

  def clear
    @keys = []
    super
  end

  def delete_if
    to_delete = []
    @keys.each{|key| to_delete.push(key) if yield(key)}
    to_delete.each{|key| delete(key)}
    map
  end

  def replace(hash)
    clear
    update(hash)
  end

# ordered container specific methods
#
  def shift
    unless empty?
      key = @keys.first
      val = delete(key)
      [key, val]
    end
  end

  def unshift(*args)
    Map.each_pair(*args) do |key, val|
      if key?(key)
        delete(key)
      else
        @keys.unshift(key)
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
        @keys.push(key)
      end
      __set__(key, val)
    end
    self
  end

  def pop
    unless empty?
      key = @keys.last
      val = delete(key)
      [key, val]
    end
  end

# misc
#
  def ==(hash)
    return false if @keys != hash.keys
    super hash
  end

  def invert
    inverted = Map.new
    inverted.default = self.default
    @keys.each{|key| inverted[self[key]] = key }
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

  def to_yaml(*args, &block)
    to_hash.to_yaml(*args, &block)
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
  def symbolize_keys!; self end
  def to_options!; self end
end

module Kernel
private
  def Map(*args, &block)
    Map.new(*args, &block)
  end
end

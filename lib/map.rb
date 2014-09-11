# -*- encoding : utf-8 -*-
class Map < Hash
  Version = '6.5.5' unless defined?(Version)
  Load = Kernel.method(:load) unless defined?(Load)

  class << Map
    def version
      Map::Version
    end

    def description
      "the awesome ruby container you've always wanted: a string/symbol indifferent ordered hash that works in all rubies"
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

    def tap(*args, &block)
      new(*args).tap do |map|
        map.tap(&block) if block
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
          k, v = pair[0..1]
          block.call(k, v)
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

    def args_for_arity(args, arity)
      arity = Integer(arity.respond_to?(:arity) ? arity.arity : arity)
      arity < 0 ? args.dup : args.slice(0, arity)
    end

    def call(object, method, *args, &block)
      args = Map.args_for_arity(args, object.method(method).arity)
      object.send(method, *args, &block)
    end

    def bcall(*args, &block)
      args = Map.args_for_arity(args, block.arity)
      block.call(*args)
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

  def Map.convert_key(key)
    key.kind_of?(Symbol) ? key.to_s : key
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
        value.map!{|v| convert_value(v)}
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

  def default=(value)
    raise ArgumentError.new("Map doesn't work so well with a non-nil default value!") unless value.nil?
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
  alias_method '+', 'merge'

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

  def delete_if(&block)
    to_delete = []

    each do |key, val|
      args = [key, val]
      to_delete.push(key) if !!Map.bcall(*args, &block)
    end

    to_delete.each{|key| delete(key)}

    self
  end

  # See: https://github.com/rubinius/rubinius/blob/98c516820d9f78bd63f29dab7d5ec9bc8692064d/kernel/common/hash19.rb#L476-L484
  def keep_if( &block )
    raise RuntimeError.new( "can't modify frozen #{ self.class.name }" ) if frozen?
    return to_enum( :keep_if ) unless block_given?
    each { | key , val | delete key unless yield( key , val ) }
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
      key = convert_key(key)
      delete(key)
      keys.unshift(key)
      __set__(key, val)
    end
    self
  end

  def push(*args)
    Map.each_pair(*args) do |key, val|
      key = convert_key(key)
      delete(key)
      keys.push(key)
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
    begin
      instance_method(:to_map)
    rescue NameError
      module_eval(<<-__, __FILE__, __LINE__)
        def #{ method }
          self
        end
      __
    end
  end

  def to_hash
    hash = Hash.new(default)
    each do |key, val|
      val = val.to_hash if val.respond_to?(:to_hash)
      hash[key] = val
    end
    hash
  end
  alias_method 'to_h', 'to_hash'

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
      when /\?$/
        key = args.shift.to_s.chomp('?')
        self.has?( key )
      else
        key = method
        unless has_key?(key)
          return(block ? fetch(key, &block) : super(*args))
        end
        self[key]
    end
  end

  def respond_to?(method, *args, &block)
    has_key = has_key?(method)
    setter = method.to_s =~ /=\Z/o
    !!((!has_key and setter) or has_key or super)
  end

  def id
    return self[:id] if has_key?(:id)
    return self[:_id] if has_key?(:_id)
    raise NoMethodError
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
      if Map.collection_has?(collection, k)
        collection = Map.collection_key(collection, k)
      else
        collection = nil
      end

      unless collection.respond_to?('[]')
        leaf = collection
        return leaf
      end
    end

    if !Map.collection_has?(collection, key) && block_given?
      yield #default_value
    else
      Map.collection_key(collection, key)
    end
  end

  def has?(*keys)
    keys = key_for(keys)
    collection = self

    return Map.collection_has?(collection, keys.first) if keys.size <= 1

    keys, key = keys[0..-2], keys[-1]

    keys.each do |k|
      if Map.collection_has?(collection, k)
        collection = Map.collection_key(collection, k)
      else
        collection = nil
      end

      return collection unless collection.respond_to?('[]')
    end

    return false unless(collection.is_a?(Hash) or collection.is_a?(Array))

    Map.collection_has?(collection, key)
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

  def blank?(*keys)
    return empty? if keys.empty?
    !has?(*keys) or Map.blank?(get(*keys))
  end

  def Map.collection_key(collection, key, &block)
    case collection
      when Array
        begin
          key = Integer(key)
        rescue
          raise(IndexError, "(#{ collection.inspect })[#{ key.inspect }]")
        end
        collection[key]

      when Hash
        collection[key]

      else
        raise(IndexError, "(#{ collection.inspect })[#{ key.inspect }]")
    end
  end

  def collection_key(*args, &block)
    Map.collection_key(*args, &block)
  end

  def Map.collection_has?(collection, key, &block)
    has_key =
      case collection
        when Array
          key = (Integer(key) rescue nil)
          !!collection.fetch(key) rescue false

        when Hash
          collection.has_key?(key)

        else
          raise(IndexError, "(#{ collection.inspect })[#{ key.inspect }]")
      end

    block.call(key) if(has_key and block)

    has_key
  end

  def collection_has?(*args, &block)
    Map.collection_has?(*args, &block)
  end

  def Map.collection_set(collection, key, value, &block)
    set_key = false

    case collection
      when Array
        begin
          key = Integer(key)
        rescue
          raise(IndexError, "(#{ collection.inspect })[#{ key.inspect }]=#{ value.inspect }")
        end
        set_key = true
        collection[key] = value

      when Hash
        set_key = true
        collection[key] = value

      else
        raise(IndexError, "(#{ collection.inspect })[#{ key.inspect }]=#{ value.inspect }")
    end

    block.call(key) if(set_key and block)

    [key, value]
  end

  def collection_set(*args, &block)
    Map.collection_set(*args, &block)
  end

  def set(*args)
    case
      when args.empty?
        return []
      when args.size == 1 && args.first.is_a?(Hash)
        hash = args.shift
      else
        hash = {}
        value = args.pop
        key = Array(args).flatten
        hash[key] = value
    end

    strategy = hash.map{|skey, svalue| [Array(skey), svalue]}

    strategy.each do |skey, svalue|
      leaf_for(skey, :autovivify => true) do |leaf, k|
        Map.collection_set(leaf, k, svalue)
      end
    end

    self
  end

  def add(*args)
    case
      when args.empty?
        return []
      when args.size == 1 && args.first.is_a?(Hash)
        hash = args.shift
      else
        hash = {}
        value = args.pop
        key = Array(args).flatten
        hash[key] = value
    end

    exploded = Map.explode(hash)

    exploded[:branches].each do |bkey, btype|
      set(bkey, btype.new) unless get(bkey).is_a?(btype)
    end

    exploded[:leaves].each do |lkey, lvalue|
      set(lkey, lvalue)
    end

    self
  end

  def Map.explode(hash)
    accum = {:branches => [], :leaves => []}

    hash.each do |key, value|
      Map._explode(key, value, accum)
    end

    branches = accum[:branches]
    leaves = accum[:leaves]

    sort_by_key_size = proc{|a,b| a.first.size <=> b.first.size}

    branches.sort!(&sort_by_key_size)
    leaves.sort!(&sort_by_key_size)

    accum
  end

  def Map._explode(key, value, accum = {:branches => [], :leaves => []})
    key = Array(key).flatten

    case value
      when Array
        accum[:branches].push([key, Array])

        value.each_with_index do |v, k|
          Map._explode(key + [k], v, accum)
        end

      when Hash
        accum[:branches].push([key, Map])

        value.each do |k, v|
          Map._explode(key + [k], v, accum)
        end

      else
        accum[:leaves].push([key, value])
    end

    accum
  end

  def Map.add(*args)
    args.flatten!
    args.compact!

    Map.for(args.shift).tap do |map|
      args.each{|arg| map.add(arg)}
    end
  end

  def Map.combine(*args)
    Map.add(*args)
  end

  def combine!(*args, &block)
    add(*args, &block)
  end

  def combine(*args, &block)
    dup.tap do |map|
      map.combine!(*args, &block)
    end
  end

  def leaf_for(key, options = {}, &block)
    leaf = self
    key = Array(key).flatten
    k = key.first

    key.each_cons(2) do |a, b|
      exists = Map.collection_has?(leaf, a)

      case b
        when Numeric
          if options[:autovivify]
            Map.collection_set(leaf, a, Array.new) unless exists
          end

        when String, Symbol
          if options[:autovivify]
            Map.collection_set(leaf, a, Map.new) unless exists
          end
      end

      leaf = Map.collection_key(leaf, a)
      k = b
    end

    block ? block.call(leaf, k) : [leaf, k]
  end

  def rm(*args)
    paths, path = args.partition{|arg| arg.is_a?(Array)}
    paths.push(path)

    paths.each do |p|
      if p.size == 1
        delete(*p)
        next
      end

      branch, leaf = p[0..-2], p[-1]
      collection = get(branch)

      case collection
        when Hash
          key = leaf
          collection.delete(key)
        when Array
          index = leaf
          collection.delete_at(index)
        else
          raise(IndexError, "(#{ collection.inspect }).rm(#{ p.inspect })")
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
    return key if key.is_a?(Numeric)

    digity, stringy, digits = %r/^(~)?(\d+)$/iomx.match(key).to_a

    digity ? stringy ? String(digits) : Integer(digits) : key
  end

  def alphanumeric_key_for(key)
    Map.alphanumeric_key_for(key)
  end

  def self.key_for(*keys)
    return keys.flatten
  end

  def key_for(*keys)
    self.class.key_for(*keys)
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
    keys
  end

  def depth_first_each(*args, &block)
    Map.depth_first_each(self, *args, &block)
  end

  def depth_first_keys(*args, &block)
    Map.depth_first_keys(self, *args, &block)
  end

  def depth_first_values(*args, &block)
    Map.depth_first_values(self, *args, &block)
  end

  def breadth_first_each(*args, &block)
    Map.breadth_first_each(self, *args, &block)
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

## for mongoid type system support
#
  def serialize(object)
    ::Map.for(object)
  end

  def deserialize(object)
    ::Map.for(object)
  end

  def Map.demongoize(object)
    Map.for(object)
  end

  def Map.evolve(object)
    Map.for(object)
  end

  def mongoize
    self
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
Map.load('params.rb')


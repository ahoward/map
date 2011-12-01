require 'testing'
require 'map'

Testing Map do
  testing 'that bare constructor werks' do
    assert{ Map.new }
  end

  testing 'that the contructor accepts a hash' do
    assert{ Map.new(hash = {}) }
  end

  testing 'that the constructor accepts the empty array' do
    array = []
    assert{ Map.new(array) }
    assert{ Map.new(*array) }
  end

  testing 'that the constructor does not die when passed nil or false' do
    assert{ Map.new(nil) }
    assert{ Map.new(false) }
  end

  testing 'that the contructor accepts an even sized array' do
    arrays = [
      [ %w( k v ), %w( key val ) ],
      [ %w( k v ), %w( key val ), %w( a b ) ],
      [ %w( k v ), %w( key val ), %w( a b ), %w( x y ) ]
    ]
    arrays.each do |array|
      assert{ Map.new(array) }
      assert{ Map.new(*array) }
    end
  end

  testing 'that the contructor accepts an odd sized array' do
    arrays = [
      [ %w( k v ) ],
      [ %w( k v ), %w( key val ), %w( a b ) ]
    ]
    arrays.each do |array|
      assert{ Map.new(array) }
      assert{ Map.new(*array) }
    end
  end

  testing 'that the constructor accepts arrays of pairs' do
    arrays = [
      [],
      [ %w( k v ) ],
      [ %w( k v ), %w( key val ) ],
      [ %w( k v ), %w( key val ), %w( a b ) ]
    ]
    arrays.each do |array|
      assert{ Map.new(array) }
      assert{ Map.new(*array) }
    end
  end

  testing 'that "[]" is a synonym for "new"' do
    list = [
      [],
      [{}],
      [[:key, :val]],
      [:key, :val]
    ]
    list.each do |args|
      map = assert{ Map[*args] }
      assert{ map.is_a?(Map) }
      assert{ Map.new(*args) == map }
    end
  end

  testing 'that #each yields pairs in order' do
    map = new_int_map
    i = 0
    map.each do |key, val|
      assert{ key == i.to_s }
      assert{ val == i }
      i += 1
    end
  end

  testing 'that keys and values are ordered' do
    n = 2048
    map = new_int_map(n)
    values = Array.new(n){|i| i}
    keys = values.map{|value| value.to_s}
    assert{ map.keys.size == n }
    assert{ map.keys == keys}
    assert{ map.values == values}
  end

  testing 'that maps are string/symbol indifferent for simple look-ups' do
    map = Map.new
    map[:k] = :v
    map['a'] = 'b'
    assert{ map[:k] == :v }
    assert{ map[:k.to_s] == :v }
    assert{ map[:a] == 'b' }
    assert{ map[:a.to_s] == 'b' }
  end

  testing 'that maps are string/symbol indifferent for recursive look-ups' do
    map = assert{ Map(:a => {:b => {:c => 42}}) }
    assert{ map[:a] = {:b => {:c => 42}} }
    assert{ map[:a][:b][:c] == 42 }
    assert{ map['a'][:b][:c] == 42 }
    assert{ map['a']['b'][:c] == 42 }
    assert{ map['a']['b']['c'] == 42 }
    assert{ map[:a]['b'][:c] == 42 }
    assert{ map[:a]['b']['c'] == 42 }
    assert{ map[:a][:b]['c'] == 42 }
    assert{ map['a'][:b]['c'] == 42 }

    map = assert{ Map(:a => [{:b => 42}]) }
    assert{ map['a'].is_a?(Array) }
    assert{ map['a'][0].is_a?(Map) }
    assert{ map['a'][0]['b'] == 42 }

    map = assert{ Map(:a => [ {:b => 42}, [{:c => 'forty-two'}] ]) }
    assert{ map['a'].is_a?(Array) }
    assert{ map['a'][0].is_a?(Map) }
    assert{ map['a'][1].is_a?(Array) }
    assert{ map['a'][0]['b'] == 42 }
    assert{ map['a'][1][0]['c'] == 'forty-two' }
  end

  testing 'that maps support shift like a good ordered container' do
    map = Map.new
    10.times do |i|
      key, val = i.to_s, i
      assert{ map.unshift(key, val) }
      assert{ map[key] == val }
      assert{ map.keys.first.to_s == key.to_s}
      assert{ map.values.first.to_s == val.to_s}
    end

    map = Map.new
    args = []
    10.times do |i|
      key, val = i.to_s, i
      args.unshift([key, val])
    end
    map.unshift(*args)
    10.times do |i|
      key, val = i.to_s, i
      assert{ map[key] == val }
      assert{ map.keys[i].to_s == key.to_s}
      assert{ map.values[i].to_s == val.to_s}
    end
  end

  testing 'the match operator, which can make testing hash equality simpler!' do
    map = new_int_map
    hash = new_int_hash
    assert{ map =~ hash }
  end

  testing 'that inheritence works without cycles' do
    c = Class.new(Map){}
    o = assert{ c.new }
    assert{ Map === o }
  end

  testing 'equality' do
    a = assert{ Map.new }
    b = assert{ Map.new }
    assert{ a == b}
    assert{ a != 42 }
    b[:k] = :v
    assert{ a != b}
  end

  testing 'simple struct usage' do
    a = assert{ Map.new(:k => :v) }
    s = assert{ a.struct }
    assert{ s.k == :v }
  end

  testing 'nested struct usage' do
    a = assert{ Map.new(:k => {:l => :v}) }
    s = assert{ a.struct }
    assert{ s.k.l == :v }
  end

  testing 'that subclassing and clobbering initialize does not kill nested coersion' do
    c = Class.new(Map){ def initialize(arg) end }
    o = assert{ c.new(42) }
    assert{ o.is_a?(c) }
    assert{ o.update(:k => {:a => :b}) }
  end

  testing 'that subclassing does not kill class level coersion' do
    c = Class.new(Map){ }
    o = assert{ c.for(Map.new) }
    assert{ o.is_a?(c) }

    d = Class.new(c)
    o = assert{ d.for(Map.new) }
    assert{ o.is_a?(d) }
  end

  testing 'that subclassing creates custom conversion methods' do
    c = Class.new(Map) do
      def self.name()
        :C
      end
    end
    assert{ c.conversion_methods.map{|x| x.to_s} == %w( to_c to_map ) }
    o = c.new
    assert{ o.respond_to?(:to_map) }
    assert{ o.respond_to?(:to_c) }

    assert{ o.update(:a => {:b => :c}) }
    assert{ o[:a].class == c }
  end

  testing 'that custom conversion methods can be added' do
    c = Class.new(Map)
    o = c.new
    foobar = {:k => :v}
    def foobar.to_foobar() self end
    c.add_conversion_method!('to_foobar')
    assert{ c.conversion_methods.map{|x| x.to_s} == %w( to_foobar to_map ) }
    o[:foobar] = foobar
    assert{ o[:foobar] =~ foobar }
  end

  testing 'that custom conversion methods are coerced - just in case' do
    map = Map.new
    record = Class.new(Hash) do
      def to_map() {:id => 42} end
    end
    map.update(:list => [record.new, record.new])
    assert{ map.list.all?{|x| x.is_a?(Map)} }
    assert{ map.list.all?{|x| x.id==42} }
  end

  testing 'that non-hashlike classes do *not* have conversion methods called on them' do
    map = Map.new
    record = Class.new do
      def to_map() {:id => 42} end
    end
    map.update(:record => record.new) 
    assert{ !map.record.is_a?(Hash) } 
    assert{ !map.record.is_a?(Map) } 
    assert{ map.record.is_a?(record) } 
  end

  testing 'that coercion is minimal' do
    map = Map.new
    a = Class.new(Map) do
      def to_map() {:k => :a} end
    end
    b = Class.new(a) do
      def to_map() {:k => :b} end
    end
    m = b.new
    m.update(:list => [a.new, b.new])
    assert{ m.list.first.class == b }
    assert{ m.list.last.class == b }
    m = a.new
    m.update(:list => [a.new, b.new])
    assert{ m.list.first.class == a }
    assert{ m.list.last.class == a }
  end

  testing 'that map supports basic option parsing for methods' do
    %w( options_for options opts ).each do |method|
      args = [0,1, {:k => :v, :a => false}]
      opts = assert{ Map.send(method, args) }
      assert{ opts.getopt(:k)==:v }
      assert{ opts.getopt(:a)==false }
      assert{ opts.getopt(:b, :default => 42)==42 }
      assert{ args.last.is_a?(Hash) }
    end
  end

  testing 'that bang option parsing can pop the options off' do
    %w( options_for! options! opts! ).each do |method|
      args = [0,1, {:k => :v, :a => false}]
      opts = assert{ Map.send(method, args) }
      assert{ !args.last.is_a?(Hash) }

      new_args = [0,1, opts]
      new_opts = assert{ Map.send(method, new_args) }
      assert{ !new_args.last.is_a?(Hash) }
    end
  end

  testing 'that maps can be converted to lists with numeric indexes' do
    m = Map[0, :a, 1, :b, 2, :c]
    assert{ m.to_list == [:a, :b, :c] }
  end

  testing 'that method_missing hacks allow setting values, but not getting them until they are set' do
    m = Map.new
    assert{ (m.missing rescue $!).is_a?(Exception) }
    assert{ m.missing = :val }
    assert{ m[:missing] == :val }
    assert{ m.missing == :val }
  end

  testing 'that method_missing hacks have sane respond_to? semantics' do
    m = Map.new
    assert{ !m.respond_to?(:missing) }
    assert{ m.respond_to?(:missing=) }
    assert{ m.missing = :val }
    assert{ m.respond_to?(:missing) }
    assert{ m.respond_to?(:missing=) }
  end

  testing 'that method missing with a block delegatets to fetch' do
    m = Map.new
    assert{ m.missing{ :val } == :val }
    assert{ !m.has_key?(:key) }
  end

  testing 'that #id werks' do
    m = Map.new
    assert{ (m.id rescue $!).is_a?(Exception) }
    m.id = 42
    assert{ m.id==42 }
  end

  testing 'that maps support compound key/val setting' do
    m = Map.new
    assert{ m.set(:a, :b, :c, 42) }
    assert{ m[:a][:b][:c] == 42 }
    assert{ m.get(:a, :b, :c) == 42 }
    assert{ m.set([:x, :y, :z] => 42.0, [:A, 2] => 'forty-two') }
    assert{ m[:A].is_a?(Array) }
    assert{ m[:A].size == 3}
    assert{ m[:A][2] == 'forty-two' }
    assert{ m[:x][:y].is_a?(Hash) }
    assert{ m[:x][:y][:z] == 42.0 }
  end

  testing 'that maps can support compound key/val setting via key.dot notation' do
    m = Class.new(Map){ dot_keys! }.new
    assert{ m.set('a.b.c', 42) }
    assert{ m[:a][:b][:c] == 42 }
    assert{ m.get('a.b.c') == 42 }
    assert{ m.set('x.y.z' => 42.0, 'A.2' => 'forty-two') }
    assert{ m[:A].is_a?(Array) }
    assert{ m[:A].size == 3}
    assert{ m[:A][2] == 'forty-two' }
    assert{ m[:x][:y].is_a?(Hash) }
    assert{ m[:x][:y][:z] == 42.0 }
    assert{ m.has?('a.b.c') }
    assert{ m.has?('x.y.z') }
    assert{ m.has?('A.2') }
  end

  testing 'that Map#get supports providing a default value in a block' do
    m = Map.new
    m.set(:a, :b, :c, 42)
    m.set(:z, 1)
    
    assert { m.get(:x) {1} == 1 }
    assert { m.get(:z) {2} == 1 }
    assert { m.get(:a, :b, :d) {1} == 1 }
    assert { m.get(:a, :b, :c) {1} == 42 }
    assert { m.get(:a, :b) {1} == Map.new({:c => 42}) }
    assert { m.get(:a, :aa) {1} == 1 }
  end

  testing 'that setting a sub-container does not eff up the container values' do
    m = Map.new
    assert{ m.set(:array => [0,1,2]) }
    assert{ m.get(:array, 0) == 0 }
    assert{ m.get(:array, 1) == 1 }
    assert{ m.get(:array, 2) == 2 }

    assert{ m.set(:array, 2, 42) }
    assert{ m.get(:array, 0) == 0 }
    assert{ m.get(:array, 1) == 1 }
    assert{ m.get(:array, 2) == 42 }
  end

  testing 'that #apply selectively merges non-nil values' do
    m = Map.new(:array => [0, 1], :hash => {:a => false, :b => nil, :c => 42})
    defaults = Map.new(:array => [nil, nil, 2], :hash => {:b => true})

    assert{ m.apply(defaults) }
    assert{ m[:array] == [0,1,2] }
    assert{ m[:hash] =~ {:a => false, :b => true, :c => 42} }
  end

  testing 'that maps support depth_first_each' do
    m = Map.new
    prefix = %w[ a b c ]
    keys = []
    n = 0.42

    10.times do |i|
      key = prefix + [i]
      val = n
      keys.push(key)
      assert{ m.set(key => val) }
      n *= 10
    end

    assert{ m.get(:a).is_a?(Hash) }
    assert{ m.get(:a, :b).is_a?(Hash) }
    assert{ m.get(:a, :b, :c).is_a?(Array) }

    n = 0.42
    m.depth_first_each do |key, val|
      assert{ key == keys.shift }
      assert{ val == n }
      n *= 10
    end
  end

  testing 'that Map.each_pair works on arrays' do
    each = []
    array = %w( a b c )
    Map.each_pair(array){|k,v| each.push(k,v)}
    assert{ each_pair = ['a', 'b', 'c', nil] }
  end

  testing 'that maps support breath_first_each' do
    map = Map[
      'hash'         , {'x' => 'y'},
      'nested hash'  , {'nested' => {'a' => 'b'}},
      'array'        , [0, 1, 2],
      'nested array' , [[3], [4], [5]],
      'string'       , '42'
    ]

    accum = []
    Map.breadth_first_each(map){|k, v| accum.push([k, v])}
    expected =
      [[["hash"], {"x"=>"y"}],
       [["nested hash"], {"nested"=>{"a"=>"b"}}],
       [["array"], [0, 1, 2]],
       [["nested array"], [[3], [4], [5]]],
       [["string"], "42"],
       [["hash", "x"], "y"],
       [["nested hash", "nested"], {"a"=>"b"}],
       [["array", 0], 0],
       [["array", 1], 1],
       [["array", 2], 2],
       [["nested array", 0], [3]],
       [["nested array", 1], [4]],
       [["nested array", 2], [5]],
       [["nested hash", "nested", "a"], "b"],
       [["nested array", 0, 0], 3],
       [["nested array", 1, 0], 4],
       [["nested array", 2, 0], 5]]
  end

  testing 'that maps have a needle-in-a-haystack like #contains? method' do
    haystack = Map[
      'hash'         , {'x' => 'y'},
      'nested hash'  , {'nested' => {'a' => 'b'}},
      'array'        , [0, 1, 2],
      'nested array' , [[3], [4], [5]],
      'string'       , '42'
    ]

    needles = [
      {'x' => 'y'},
      {'nested' => {'a' => 'b'}},
      {'a' => 'b'},
      [0,1,2],
      [[3], [4], [5]],
      [3],
      [4],
      [5],
      '42',
      0,1,2,
      3,4,5
    ]

    needles.each do |needle|
      assert{ haystack.contains?(needle) }
    end
  end

  testing 'that #update and #replace accept map-ish objects' do
    o = Object.new
    def o.to_map() {:k => :v} end
    m = Map.new
    assert{ m.update(o) }
    assert{ m =~ {:k => :v} }
    m[:a] = :b
    assert{ m.replace(o) }
    assert{ m =~ {:k => :v} }
  end

  testing 'that maps with un-marshal-able objects can be copied' do
    open(__FILE__) do |f|
      f
      m = Map.for(:f => f)
      assert{ m.copy }
      assert{ m.dup }
      assert{ m.clone }
    end
  end

  testing 'that maps have a blank? method that is sane' do
    m = Map.new(:a => 0, :b => ' ', :c => '', :d => {}, :e => [], :f => false)
    m.each do |key, val|
      assert{ m.blank?(key) }
    end

    m = Map.new(:a => 1, :b => '_', :d => {:k=>:v}, :e => [42], :f => true)
    m.each do |key, val|
      assert{ !m.blank?(key) }
    end

    assert{ Map.new.blank? }
  end

  testing 'that self referential maps do not make #inspect puke' do
    a = Map.new
    b = Map.new

    b[:a] = a
    a[:b] = b

    assert do
      begin
        a.inspect
        b.inspect
        true
      rescue Object
        false
      end
    end
  end

  testing 'that maps a clever little rm operator' do
    map = Map.new
    map.set :a, :b, 42
    map.set :x, :y, 42
    map.set :x, :z, 42
    map.set :array, [0,1,2]

    assert{ map.rm(:x, :y) }
    assert{ map.get(:x) =~ {:z => 42} }
    
    assert{ map.rm(:a, :b) }
    assert{ map.get(:a) =~ {} }

    assert{ map.rm(:array, 0) }
    assert{ map.get(:array) == [1,2] }
    assert{ map.rm(:array, 1) }
    assert{ map.get(:array) == [1] }
    assert{ map.rm(:array, 0) }
    assert{ map.get(:array) == [] }

    assert{ map.rm(:array) }
    assert{ map.get(:array).nil? }

    assert{ map.rm(:a) }
    assert{ map.get(:a).nil? }

    assert{ map.rm(:x) }
    assert{ map.get(:x).nil? }
  end

  testing 'that maps a clever little question method' do
    m = Map.new
    m.set(:a, :b, :c, 42)
    m.set([:x, :y, :z] => 42.0, [:A, 2] => 'forty-two')

    assert( !m.b? )
    assert( m.a? )
    assert( m.a.b? )
    assert( m.a.b.c? )
    assert( !m.a.b.d? )

    assert( m.x? )
    assert( m.x.y? )
    assert( m.x.y.z? )
    assert( !m.y? )

    assert( m.A? )
  end

  testing 'that maps have a clever little question method on Struct' do
    m = Map.new
    m.set(:a, :b, :c, 42)
    m.set([:x, :y, :z] => 42.0, [:A, 2] => 'forty-two')
    s = m.struct

    assert( s.a.b.c == 42   )
    assert( s.x.y.z == 42.0 )

    assert( !s.b? )
    assert( s.a? )
    assert( s.a.b? )
    assert( s.a.b.c? )
    assert( !s.a.b.d? )

    assert( s.x? )
    assert( s.x.y? )
    assert( s.x.y.z? )
    assert( !s.y? )

    assert( s.A? )

  end

  testing 'that Map#default= blows up until a sane strategy for dealing with it is developed' do
    m = Map.new

    assert do
      begin
        m.default = 42
      rescue Object => e
        e.is_a?(ArgumentError)
      end
    end
  end

protected
  def new_int_map(n = 1024)
    map = assert{ Map.new }
    n.times{|i| map[i.to_s] = i}
    map
  end

  def new_int_hash(n = 1024)
    hash = Hash.new
    n.times{|i| hash[i.to_s] = i}
    hash
  end
end






BEGIN {
  testdir = File.dirname(File.expand_path(__FILE__))
  testlibdir = File.join(testdir, 'lib')
  rootdir = File.dirname(testdir)
  libdir = File.join(rootdir, 'lib')
  $LOAD_PATH.push(libdir)
  $LOAD_PATH.push(testlibdir)
}

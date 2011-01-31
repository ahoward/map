require 'testing'
require 'map'

Testing Map do
  testing 'that bare constructor werks' do
    assert{ Map.new }
  end

  testing 'that the contructor accepts a hash' do
    assert{ Map.new(hash = {}) }
  end

  testing 'that the contructor accepts a hash and preserves the default value' do
    hash = {}
    hash.default = 42
    assert{ hash[:missing] == 42 }
    map = assert{ Map.new(hash) }
    assert{ map[:missing] == 42 }
  end

  testing 'that the constructor accepts the empty array' do
    array = []
    assert{ Map.new(array) }
    assert{ Map.new(*array) }
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
    assert{ o[:foobar] == foobar }
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
    end
  end

  testing 'that maps can be converted to lists with numeric indexes' do
    m = Map[0, :a, 1, :b, 2, :c]
    assert{ m.to_list == [:a, :b, :c] }
  end

  testing 'that method missing hacks allow setting values, but not getting them until they are set' do
    m = Map.new
    assert{ (m.key rescue $!).is_a?(Exception) }
    assert{ m.key = :val }
    assert{ m[:key] == :val }
    assert{ m.key == :val }
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

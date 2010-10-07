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
    assert{ map[:a] = {:b => {:c, 42}} }
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

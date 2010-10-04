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
    map = Map.new
    assert{ map[:a] = Map[:b, 42] }
    assert{ map[:a][:b] = Map[:c, 42] }
    assert{ map[:a][:b][:c] == 42 }
    assert{ map['a'][:b][:c] == 42 }
    assert{ map['a']['b'][:c] == 42 }
    assert{ map['a']['b']['c'] == 42 }
    assert{ map[:a]['b'][:c] == 42 }
    assert{ map[:a]['b']['c'] == 42 }
    assert{ map[:a][:b]['c'] == 42 }
    assert{ map['a'][:b]['c'] == 42 }
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

  testing 'that to_hash with a parameter returns a hash with an ordering key' do
    map = Map.new
    map.push 'k3', 'v3'
    map.push 'k1', 'v1'
    map.push 'k2', 'v2'
    assert {map.keys == ['k3', 'k1', 'k2']}

    hash = map.to_hash true
    assert {hash['k1'] == 'v1'}
    assert {hash['_order'] == ['k3', 'k1', 'k2']}
  end

  testing 'that to_hash with a parameter returns a hash with a custom ordering key' do
    map = Map.new
    map.push 'k3', 'v3'
    map.push 'k1', 'v1'
    map.push 'k2', 'v2'
    assert {map.keys == ['k3', 'k1', 'k2']}

    hash = map.to_hash '___order'
    assert {hash['k1'] == 'v1'}
    assert {hash['___order'] == ['k3', 'k1', 'k2']}
  end

  testing 'that creating with an extra parameter adds order' do
    map = Map.new({'a' => 3, 'c' => 2, 'l' => 9, '_order' => ['l', 'a', 'c']}, true)
    assert {map.keys == ['l', 'a', 'c']}
  end

  testing 'that creating with an extra parameter adds order' do
    map = Map.new({'a' => 3, 'c' => 2, 'l' => 9, '___order' => ['l', 'a', 'c']}, '___order')
    assert {map.keys == ['l', 'a', 'c']}
  end

protected
  def new_int_map(n = 1024)
    map = Map.new
    n.times{|i| map[i.to_s] = i}
    map
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

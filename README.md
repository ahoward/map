NAME
----
  map.rb


LOGO
----
  ![weed whacking giraffe]('https://github.com/ahoward/map/blob/master/images/map.png')


SYNOPSIS
--------
  the awesome ruby container you've always wanted: a string/symbol indifferent
  ordered hash that works in all rubies.

  maps are bitchin ordered hashes that are both ordered, string/symbol
  indifferent, and have all sorts of sweetness like recursive conversion, more
  robust, not to mention dependency-less, implementation than
  HashWithIndifferentAccess.

  bestiest of all, maps support some very powerful tree-like iterators that
  make working with structured data, like json, insanely simple.

  map.rb has been in production usage for 14 years and is commensurately
  hardened.  if you process json, you will love map.rb


INSTALL
-------
  gem install map


URI
---
  http://github.com/ahoward/map


DESCRIPTION
-----------

> maps are always ordered.  constructing them in an ordered fashion builds
> them that way, although the normal hash contructor is also supported
>
```ruby

  m = Map[:k, :v, :key, :val]
  m = Map(:k, :v, :key, :val)
  m = Map.new(:k, :v, :key, :val)

  m = Map[[:k, :v], [:key, :val]]
  m = Map(:k => :v, :key => :val)  # ruh-oh, the input hash loses order!
  m = Map.new(:k => :v, :key => :val)  # ruh-oh, the input hash loses order!

  m = Map.new
  m[:a] = 0
  m[:b] = 1
  m[:c] = 2

  p m.keys   #=> ['a','b','c']  ### always ordered!
  p m.values #=> [0,1,2]        ### always ordered!

```

> maps don't care about symbol vs.string keys
>
```ruby

  p m[:a]  #=> 0
  p m["a"] #=> 0

```

> even via deep nesting 
>
```ruby

  p m[:foo]['bar'][:baz]  #=> 42

```

> many functions operate in a way one would expect from an ordered container
>
```ruby

  m.update(:k2 => :v2)
  m.update(:k2, :v2)

  key_val_pair = m.shift
  key_val_pair = m.pop

```

> maps keep mapiness for even deep operations
>
```ruby

  m.update :nested => {:hashes => {:are => :converted}}

```

> maps can give back clever little struct objects
>
```ruby

  m = Map(:foo => {:bar => 42})
  s = m.struct
  p s.foo.bar #=> 42

```

> because option parsing is such a common use case for needing string/symbol
> indifference map.rb comes out of the box loaded with option support
>
```ruby

  def foo(*args, &block)
    opts = Map.options(args)
    a = opts.getopt(:a)
    b = opts.getopt(:b, :default => false)
  end


  opts = Map.options(:a => 42, :b => nil, :c => false)
  opts.getopt(:a)                    #=> 42
  opts.getopt(:b)                    #=> nil
  opts.getopt(:b, :default => 42)    #=> 42 
  opts.getopt(:c)                    #=> false
  opts.getopt(:d, :default => false) #=> false

```

> this avoids such bugs as
>
```ruby

  options = {:read_only => false}
  read_only = options[:read_only] || true  # should be false but is true

```

> with options this becomes
>
```ruby

  options = Map.options(:read_only => true)
  read_only = options.getopt(:read_only, :default => false) #=> true

```

> maps support some really nice operators that hashes/orderedhashes do not
>
```ruby

  m = Map.new
  m.set(:h, :a, 0, 42)
  m.has?(:h, :a)         #=> true
  p m                    #=> {'h' => {'a' => [42]}} 
  m.set(:h, :a, 1, 42.0)
  p m                    #=> {'h' => {'a' => [42, 42.0]}} 

  m.get(:h, :a, 1)       #=> 42.0
  m.get(:x, :y, :z)      #=> nil
  m[:x][:y][:z]          #=> raises exception!

  m = Map.new(:array => [0,1])
  defaults = {:array => [nil, nil, 2]}
  m.apply(defaults)
  p m[:array]            #=> [0,1,2]

```

> they also support some *powerful* tree-ish iteration styles
>
```ruby

  m = Map.new

  m.set(
    [:a, :b, :c, 0] => 0,
    [:a, :b, :c, 1] => 10,
    [:a, :b, :c, 2] => 20,
    [:a, :b, :c, 3] => 30
  )

  m.set(:x, :y, 42)
  m.set(:x, :z, 42.0)

  m.depth_first_each do |key, val|
    p key => val
  end

  #=> [:a, :b, :c, 0] => 0
  #=> [:a, :b, :c, 1] => 10
  #=> [:a, :b, :c, 2] => 20
  #=> [:a, :b, :c, 3] => 30
  #=> [:x, :y] => 42
  #=> [:x, :z] => 42.0

```


TESTING
-------

map.rb supports two ordering implementations:

1. **Ruby 1.9+**: Uses native Hash ordering (memory optimized, no @keys array)
2. **Ruby < 1.9**: Uses Map::Ordering module with explicit @keys array

### Testing Both Code Paths

The `MAP_FORCE_ORDERING=1` environment variable forces inclusion of the Map::Ordering
module **on Ruby >= 1.9 only**, allowing you to test the legacy ordering code path on
modern Ruby versions. (On Ruby < 1.9, the module is always included regardless of this
setting, since it's required for Hash ordering.)

```sh
# Test with native Hash ordering (Ruby 1.9+ default)
rake test
rake test:without_ordering

# Test with Map::Ordering module (simulates Ruby < 1.9)
MAP_FORCE_ORDERING=1 rake test
rake test:with_ordering

# Quick verification of both modes
ruby test/verify_ordering.rb
MAP_FORCE_ORDERING=1 ruby test/verify_ordering.rb
```

Both modes pass the same 56 tests with 4940 assertions, proving functional equivalence.

### Testing Across Ruby Versions

**Quick validation (RECOMMENDED):**

```sh
# Test both code paths on your current Ruby
./test_hash_ordering.sh

# Summary output shows:
#   - Native mode: no @keys (optimized)
#   - Forced mode: has @keys (simulates Ruby < 1.9)
#   - Both: 56 tests, 4940 assertions pass
```

**Test across multiple Ruby versions:**

```sh
# Test all installed Ruby versions automatically
./test_all_rubies.sh

# Or manually test with specific Ruby versions
RBENV_VERSION=3.2.8 ./test_hash_ordering.sh
RBENV_VERSION=3.3.4 rake test
RBENV_VERSION=3.3.4 MAP_FORCE_ORDERING=1 rake test
```

**Note**: Old Ruby Docker images (< 2.0) are no longer available. Use `MAP_FORCE_ORDERING=1`
to test the Ruby < 1.9 code path on modern Ruby - it uses the exact same `Map::Ordering`
module with the same `@keys` array logic and behavior.

**CI/CD testing:**

The `.github/workflows/test.yml` workflow automatically tests across Ruby 2.7, 3.0,
3.1, 3.2, 3.3, and head on every push and pull request, running both with and without
the ordering module.


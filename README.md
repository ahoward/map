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

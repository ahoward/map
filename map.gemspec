## map.gemspec
#

Gem::Specification::new do |spec|
  spec.name = "map"
  spec.version = "7.0.0"
  spec.required_ruby_version = '>= 3.0'
  spec.platform = Gem::Platform::RUBY
  spec.summary = "the perfect ruby data structure"
  spec.description = "map.rb is a string/symbol indifferent ordered hash that works in all rubies.\n\nout of the over 200 ruby gems i have written, this is the one i use\nevery day, in all my projects.\n\nsome may be accustomed to using ActiveSupport::HashWithIndiffentAccess\nand, although there are some similarities, map.rb is more complete,\nworks without requiring a mountain of code, and has been in production\nusage for over 15 years.\n\nit has no dependencies, and suports a myriad of other, 'tree-ish'\noperators that will allow you to slice and dice data like a giraffee\nwith a giant weed whacker."
  spec.license = "Ruby"

  spec.files =
["LICENSE",
 "README",
 "README.md",
 "Rakefile",
 "images",
 "images/giraffe.jpeg",
 "images/map.png",
 "lib",
 "lib/map",
 "lib/map.rb",
 "lib/map/_lib.rb",
 "lib/map/options.rb",
 "map.gemspec",
 "test",
 "test/leak.rb",
 "test/lib",
 "test/lib/testing.rb",
 "test/map_test.rb"]

  spec.executables = []
  
  spec.require_path = "lib"

  

  spec.extensions.push(*[])

  spec.author = "Ara T. Howard"
  spec.email = "ara.t.howard@gmail.com"
  spec.homepage = "https://github.com/ahoward/map"
end

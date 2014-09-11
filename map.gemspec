## map.gemspec
#

Gem::Specification::new do |spec|
  spec.name = "map"
  spec.version = "6.5.5"
  spec.platform = Gem::Platform::RUBY
  spec.summary = "map"
  spec.description = "the awesome ruby container you've always wanted: a string/symbol indifferent ordered hash that works in all rubies"
  spec.license = "same as ruby's"

  spec.files =
["LICENSE",
 "README",
 "Rakefile",
 "a.rb",
 "lib",
 "lib/map",
 "lib/map.rb",
 "lib/map/integrations",
 "lib/map/integrations/active_record.rb",
 "lib/map/options.rb",
 "lib/map/params.rb",
 "lib/map/struct.rb",
 "map.gemspec",
 "test",
 "test/leak.rb",
 "test/lib",
 "test/lib/testing.rb",
 "test/map_test.rb"]

  spec.executables = []
  
  spec.require_path = "lib"

  spec.test_files = nil

  

  spec.extensions.push(*[])

  spec.rubyforge_project = "codeforpeople"
  spec.author = "Ara T. Howard"
  spec.email = "ara.t.howard@gmail.com"
  spec.homepage = "https://github.com/ahoward/map"
end

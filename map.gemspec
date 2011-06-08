## map.gemspec
#

Gem::Specification::new do |spec|
  spec.name = "map"
  spec.version = "4.2.0"
  spec.platform = Gem::Platform::RUBY
  spec.summary = "map"
  spec.description = "description: map kicks the ass"

  spec.files =
["README",
 "Rakefile",
 "TODO",
 "lib",
 "lib/map",
 "lib/map.rb",
 "lib/map/options.rb",
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

### spec.add_dependency 'lib', '>= version'
#### spec.add_dependency 'map'

  spec.extensions.push(*[])

  spec.rubyforge_project = "codeforpeople"
  spec.author = "Ara T. Howard"
  spec.email = "ara.t.howard@gmail.com"
  spec.homepage = "https://github.com/ahoward/map"
end

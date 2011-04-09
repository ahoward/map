## map.gemspec
#

Gem::Specification::new do |spec|
  spec.name = "map"
  spec.version = "2.8.0"
  spec.platform = Gem::Platform::RUBY
  spec.summary = "map"
  spec.description = "description: map kicks the ass"

  spec.files = ["lib", "lib/map", "lib/map/options.rb", "lib/map/struct.rb", "lib/map.rb", "map.gemspec", "Rakefile", "README", "test", "test/lib", "test/lib/testing.rb", "test/map_test.rb", "TODO"]
  spec.executables = []
  
  spec.require_path = "lib"

  spec.has_rdoc = true
  spec.test_files = nil
  #spec.add_dependency 'lib', '>= version'
  #spec.add_dependency 'fattr'

  spec.extensions.push(*[])

  spec.rubyforge_project = "codeforpeople"
  spec.author = "Ara T. Howard"
  spec.email = "ara.t.howard@gmail.com"
  spec.homepage = "http://github.com/ahoward/map/tree/master"
end

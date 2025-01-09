This.author = "Ara T. Howard"
This.email = "ara.t.howard@gmail.com"
This.github = "ahoward"
This.homepage = "https://github.com/#{ This.github }/#{ This.basename }"
This.repo = "https://github.com/#{ This.github }/#{ This.basename }"

task :license do
  open('LICENSE', 'w'){|fd| fd.puts "Ruby"}
end

task :default do
  puts((Rake::Task.tasks.map{|task| task.name.gsub(/::/,':')} - ['default']).sort)
end

task :test do
  run_tests!
end

namespace :test do
  task(:unit){ run_tests!(:unit) }
  task(:functional){ run_tests!(:functional) }
  task(:integration){ run_tests!(:integration) }
end

def run_tests!(which = nil)
  which ||= '**'
  test_dir = File.join(This.dir, "test")
  test_glob ||= File.join(test_dir, "#{ which }/**_test.rb")
  test_rbs = Dir.glob(test_glob).sort
        
  div = ('=' * 119)
  line = ('-' * 119)

  test_rbs.each_with_index do |test_rb, index|
    testno = index + 1
    command = "#{ This.ruby } -w -I ./lib -I ./test/lib #{ test_rb }"

    puts
    say(div, :color => :cyan, :bold => true)
    say("@#{ testno } => ", :bold => true, :method => :print)
    say(command, :color => :cyan, :bold => true)
    say(line, :color => :cyan, :bold => true)

    system(command)

    say(line, :color => :cyan, :bold => true)

    status = $?.exitstatus

    if status.zero? 
      say("@#{ testno } <= ", :bold => true, :color => :white, :method => :print)
      say("SUCCESS", :color => :green, :bold => true)
    else
      say("@#{ testno } <= ", :bold => true, :color => :white, :method => :print)
      say("FAILURE", :color => :red, :bold => true)
    end
    say(line, :color => :cyan, :bold => true)

    exit(status) unless status.zero?
  end
end


task :gemspec do
  ignore_extensions = ['git', 'svn', 'tmp', /sw./, 'bak', 'gem']
  ignore_directories = ['pkg']
  ignore_files = ['test/log']

  shiteless = 
    lambda do |list|
      list.delete_if do |entry|
        next unless test(?e, entry)
        extension = File.basename(entry).split(%r/[.]/).last
        ignore_extensions.any?{|ext| ext === extension}
      end

      list.delete_if do |entry|
        next unless test(?d, entry)
        dirname = File.expand_path(entry)
        ignore_directories.any?{|dir| File.expand_path(dir) == dirname}
      end

      list.delete_if do |entry|
        next unless test(?f, entry)
        filename = File.expand_path(entry)
        ignore_files.any?{|file| File.expand_path(file) == filename}
      end
    end

  name        = This.basename
  object      = This.object
  version     = This.version
  files       = shiteless[Dir::glob("**/**")]
  executables = shiteless[Dir::glob("bin/*")].map{|exe| File.basename(exe)}
  summary     = Util.unindent(This.summary).strip
  description = Util.unindent(This.description).strip
  license     = This.license.strip

  if This.extensions.nil?
    This.extensions = []
    extensions = This.extensions
    %w( Makefile configure extconf.rb ).each do |ext|
      extensions << ext if File.exist?(ext)
    end
  end
  extensions = [extensions].flatten.compact

  if This.dependencies.nil?
    dependencies = []
  else
    case This.dependencies
      when Hash
        dependencies = This.dependencies.values
      when Array
        dependencies = This.dependencies
    end
  end

  template = 
    if test(?e, 'gemspec.erb')
      Template{ IO.read('gemspec.erb') }
    else
      Template {
        <<-__
          ## <%= name %>.gemspec
          #

          Gem::Specification::new do |spec|
            spec.name = <%= name.inspect %>
            spec.version = <%= version.inspect %>
            spec.required_ruby_version = '>= 3.0'
            spec.platform = Gem::Platform::RUBY
            spec.summary = <%= summary.inspect %>
            spec.description = <%= description.inspect %>
            spec.license = <%= license.inspect %>

            spec.files =\n<%= files.sort.pretty_inspect %>
            spec.executables = <%= executables.inspect %>
            
            spec.require_path = "lib"

            <% dependencies.each do |lib_version| %>
              spec.add_dependency(*<%= Array(lib_version).flatten.inspect %>)
            <% end %>

            spec.extensions.push(*<%= extensions.inspect %>)

            spec.author = <%= This.author.inspect %>
            spec.email = <%= This.email.inspect %>
            spec.homepage = <%= This.homepage.inspect %>
          end
        __
      }
    end

  Fu.mkdir_p(This.pkgdir)
  gemspec = "#{ name }.gemspec"
  open(gemspec, "w"){|fd| fd.puts(template)}
  This.gemspec = gemspec
end

task :gem => [:clean, :gemspec] do
  Fu.mkdir_p(This.pkgdir)
  before = Dir['*.gem']
  cmd = "gem build #{ This.gemspec }"
  `#{ cmd }`
  after = Dir['*.gem']
  gem = ((after - before).first || after.first) or abort('no gem!')
  Fu.mv(gem, This.pkgdir)
  This.gem = File.join(This.pkgdir, File.basename(gem))
end

task :README => [:readme]

task :readme do
  samples = ''
  prompt = '~ > '
  lib = This.lib
  version = This.version

  Dir['sample*/**/**.rb'].sort.each do |sample|
    link = "[#{ sample }](#{ This.repo }/blob/main/#{ sample })"
    samples << "  #### <========< #{ link } >========>\n"

    cmd = "cat #{ sample }"
    samples << "```sh\n"
    samples << Util.indent(prompt + cmd, 2) << "\n"
    samples << "```\n"
    samples << "```ruby\n"
    samples << Util.indent(IO.binread(sample), 4) << "\n"
    samples << "```\n"

    samples << "\n"

    cmd = "ruby #{ sample }"
    samples << "```sh\n"
    samples << Util.indent(prompt + cmd, 2) << "\n"
    samples << "```\n"

    cmd = "ruby -e'STDOUT.sync=true; exec %(ruby -I ./lib #{ sample })'"
    oe = `#{ cmd } 2>&1`
    samples << "```txt\n"
    samples << Util.indent(oe, 4) << "\n"
    samples << "```\n"

    samples << "\n"
  end

  This.samples = samples

  template = 
    case
    when test(?e, 'README.md.erb')
      Template{ IO.read('README.md.erb') }
    when test(?e, 'README.erb')
      Template{ IO.read('README.erb') }
    else
      Template {
        <<-__
          NAME
            #{ lib }

          DESCRIPTION

          INSTALL
            gem install #{ lib }

          SAMPLES
            #{ samples }
        __
      }
    end

  IO.binwrite('README.md', template)
end

task :clean do
  Dir[File.join(This.pkgdir, '**/**')].each{|entry| Fu.rm_rf(entry)}
end

task :release => [:dist, :gem] do
  gems = Dir[File.join(This.pkgdir, '*.gem')].flatten
  abort "which one? : #{ gems.inspect }" if gems.size > 1
  abort "no gems?" if gems.size < 1

  cmd = "gem push #{ This.gem }"
  puts cmd
  puts
  system(cmd)
  abort("cmd(#{ cmd }) failed with (#{ $?.inspect })") unless $?.exitstatus.zero?
end





BEGIN {
# support for this rakefile
#
  $VERBOSE = nil

  require 'ostruct'
  require 'erb'
  require 'fileutils'
  require 'rbconfig'
  require 'pp'

# fu shortcut!
#
  Fu = FileUtils

# guess a bunch of stuff about this rakefile/environment based on the
#
  This = OpenStruct.new

  This.file = File.expand_path(__FILE__)
  This.dir = File.dirname(This.file)
  This.pkgdir = File.join(This.dir, 'pkg')
  This.basename = File.basename(This.dir)

# load actual shit _lib
#
  _libpath = ["./lib/#{ This.basename }/_lib.rb", "./lib/#{ This.basename }.rb"]
  _lib = _libpath.detect{|l| test(?s, l)}

  abort "could not find a _lib in ./lib/ via #{ _libpath.join(':') }" unless _lib

  This._lib = _lib
  require This._lib

# extract the name from the _lib
#
  lines = IO.binread(This._lib).split("\n")
  re = %r`\A \s* (module|class) \s+ ([^\s]+) \s* \z`iomx
  name = nil
  lines.each do |line|
    match = line.match(re)
    if match
      name = match.to_a.last
      break
    end
  end
  unless name
    abort "could not extract `name` from #{ This._lib }"
  end
  This.name = name
  This.basename = This.name.downcase

# now, fully grok This 
#
  This.object       = eval(This.name)
  This.version      = This.object.version
  This.dependencies = This.object.dependencies
  This.summary      = This.object.summary
  This.description  = This.object.respond_to?(:description) ? This.object.description : This.summary
  This.license      = This.object.respond_to?(:license) ? This.object.license : IO.binread('LICENSE').strip

# discover full path to this ruby executable
#
  c = RbConfig::CONFIG
  bindir = c["bindir"] || c['BINDIR']
  ruby_install_name = c['ruby_install_name'] || c['RUBY_INSTALL_NAME'] || 'ruby'
  ruby_ext = c['EXEEXT'] || ''
  ruby = File.join(bindir, (ruby_install_name + ruby_ext))
  This.ruby = ruby

# some utils, alwayze teh utils...
#
  module Util
    def indent(s, n = 2)
      s = unindent(s)
      ws = ' ' * n
      s.gsub(%r/^/, ws)
    end

    def unindent(s)
      indent = nil
      s.each_line do |line|
      next if line =~ %r/^\s*$/
      indent = line[%r/^\s*/] and break
    end
    unindented = indent ? s.gsub(%r/^#{ indent }/, "") : s
    unindented.strip
  end
    extend self
  end

# template support
#
  class Template
    def Template.indent(string, n = 2)
      string = string.to_s
      n = n.to_i
      padding = (42 - 10).chr * n
      initial = %r/^#{ Regexp.escape(padding) }/
      #require 'debug'
      #binding.break
      Util.indent(string, n).sub(initial, '')
    end
    def initialize(&block)
      @block = block
      @template = block.call.to_s
    end
    def expand(b=nil)
      ERB.new(Util.unindent(@template), trim_mode: '%<>-').result((b||@block).binding)
    end
    alias_method 'to_s', 'expand'
  end
  def Template(*args, &block) Template.new(*args, &block) end

# os / platform support 
#
  module Platform
    def Platform.windows?
      (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
    end

    def Platform.darwin?
     (/darwin/ =~ RUBY_PLATFORM) != nil
    end

    def Platform.mac?
      Platform.darwin?
    end

    def Platform.unix?
      !Platform.windows?
    end

    def Platform.linux?
      Platform.unix? and not Platform.darwin?
    end

    def Platform.jruby?
      RUBY_ENGINE == 'jruby'
    end
  end

# colored console output support
#
  This.ansi = {
    :clear      => "\e[0m",
    :reset      => "\e[0m",
    :erase_line => "\e[K",
    :erase_char => "\e[P",
    :bold       => "\e[1m",
    :dark       => "\e[2m",
    :underline  => "\e[4m",
    :underscore => "\e[4m",
    :blink      => "\e[5m",
    :reverse    => "\e[7m",
    :concealed  => "\e[8m",
    :black      => "\e[30m",
    :red        => "\e[31m",
    :green      => "\e[32m",
    :yellow     => "\e[33m",
    :blue       => "\e[34m",
    :magenta    => "\e[35m",
    :cyan       => "\e[36m",
    :white      => "\e[37m",
    :on_black   => "\e[40m",
    :on_red     => "\e[41m",
    :on_green   => "\e[42m",
    :on_yellow  => "\e[43m",
    :on_blue    => "\e[44m",
    :on_magenta => "\e[45m",
    :on_cyan    => "\e[46m",
    :on_white   => "\e[47m"
  }
  def say(phrase, *args)
    options = args.last.is_a?(Hash) ? args.pop : {}
    options[:color] = args.shift.to_s.to_sym unless args.empty?
    keys = options.keys
    keys.each{|key| options[key.to_s.to_sym] = options.delete(key)}

    color = options[:color]
    bold = options.has_key?(:bold)

    parts = [phrase]
    parts.unshift(This.ansi[color]) if color
    parts.unshift(This.ansi[:bold]) if bold
    parts.push(This.ansi[:clear]) if parts.size > 1

    method = options[:method] || :puts

    Kernel.send(method, parts.join)
  end

# always run out of the project dir
#
  Dir.chdir(This.dir)
}

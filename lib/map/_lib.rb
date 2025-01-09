class Map
  VERSION = '7.0.0'

  class << Map
    def version
      VERSION
    end

    def repo
      'https://github.com/ahoward/map'
    end

    def summary
      <<~____
        the perfect ruby data structure
      ____
    end

    def description
      <<~____
        map.rb is a string/symbol indifferent ordered hash that works in all rubies.

        out of the over 200 ruby gems i have written, this is the one i use
        every day, in all my projects.

        some may be accustomed to using ActiveSupport::HashWithIndiffentAccess
        and, although there are some similarities, map.rb is more complete,
        works without requiring a mountain of code, and has been in production
        usage for over 15 years.

        it has no dependencies, and suports a myriad of other, 'tree-ish'
        operators that will allow you to slice and dice data like a giraffee
        with a giant weed whacker.
      ____
    end

    def libs
      %w[
      ]
    end

    def dependencies
      {
      }
    end

    def libdir(*args, &block)
      @libdir ||= File.dirname(File.expand_path(__FILE__))
      args.empty? ? @libdir : File.join(@libdir, *args)
    ensure
      if block
        begin
          $LOAD_PATH.unshift(@libdir)
          block.call
        ensure
          $LOAD_PATH.shift
        end
      end
    end

    def load(*libs)
      libs = libs.join(' ').scan(/[^\s+]+/)
      libdir { libs.each { |lib| Kernel.load(lib) } }
    end

    def load_dependencies!
      libs.each do |lib|
        require lib
      end

      begin
        require 'rubygems'
      rescue LoadError
        nil
      end

      has_rubygems = defined?(gem)

      dependencies.each do |lib, dependency|
        gem(*dependency) if has_rubygems
        require(lib)
      end
    end
  end
end

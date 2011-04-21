class Map
  module Options
    class << Options
      def for(arg)
        hash =
          case arg
            when Hash
              arg
            when Array
              parse(arg)
            when String, Symbol
              {arg => true}
            else
              raise(ArgumentError, arg.inspect) unless arg.respond_to?(:to_hash)
              arg.to_hash
          end
        map = Map.coerce(hash)
      ensure
        map.extend(Options) unless map.is_a?(Options)
      end

      def parse(arg)
        case arg
          when Array
            arg.extend(Arguments) unless arg.is_a?(Arguments)
            arg.options
          when Hash
            Options.for(arg)
          else
            raise(ArgumentError, "`arg` should be an Array or Hash")
        end
      end
    end

    attr_accessor :arguments

    %w( to_options stringify_keys ).each do |method|
      module_eval <<-__, __FILE__, __LINE__
        def #{ method }() dup end
        def #{ method }!() self end
      __
    end

    def get_opt(opts, options = {})
      options = Map.for(options.is_a?(Hash) ? options : {:default => options})
      default = options[:default]
      [ opts ].flatten.each do |opt|
        return fetch(opt) if has_key?(opt)
      end
      default
    end
    alias_method('getopt', 'get_opt')

    def get_opts(*opts)
      opts.flatten.map{|opt| getopt(opt)}
    end
    alias_method('getopts', 'get_opts')

    def has_opt(opts)
      [ opts ].flatten.each do |opt|
        return true if has_key?(opt)
      end
      false
    end
    alias_method('hasopt', 'has_opt')
    alias_method('hasopt?', 'has_opt')
    alias_method('has_opt?', 'has_opt')

    def has_opts(*opts)
      opts.flatten.all?{|opt| hasopt(opt)}
    end
    alias_method('hasopts?', 'has_opts')
    alias_method('has_opts?', 'has_opts')

    def del_opt(opts)
      [ opts ].flatten.each do |opt|
        return delete(opt) if has_key?(opt)
      end
      nil
    end
    alias_method('delopt', 'del_opt')

    def del_opts(*opts)
      opts.flatten.map{|opt| delopt(opt)}
      opts
    end
    alias_method('delopts', 'del_opts')
    alias_method('delopts!', 'del_opts')

    def set_opt(opts, value = nil)
      [ opts ].flatten.each do |opt|
        return self[opt]=value
      end
      return value
    end
    alias_method('setopt', 'set_opt')
    alias_method('setopt!', 'set_opt')

    def set_opts(opts)
      opts.each{|key, value| setopt(key, value)}
      opts
    end
    alias_method('setopts', 'set_opts')
    alias_method('setopts!', 'set_opts')

    def pop
      pop! unless popped?
      self
    end

    def popped?
      defined?(@popped) and @popped
    end

    def pop!
      if arguments.last.is_a?(Hash)
        @popped = arguments.pop
      else
        @popped = true
      end
    end
  end

  module Arguments
    def options
      @options ||= Options.for(last.is_a?(Hash) ? last : {})
    ensure
      @options.arguments = self
    end

    class << Arguments
      def for(args)
        args.extend(Arguments) unless args.is_a?(Arguments)
        args
      end

      def parse(args)
        [args, Options.parse(args)]
      end
    end
  end
end


def Map.options_for(*args, &block)
  Map::Options.for(*args, &block)
end

def Map.options_for!(*args, &block)
  Map::Options.for(*args, &block).pop
end

def Map.update_options_for!(args, &block)
  options = Map.options_for!(args)
  block.call(options)
ensure
  args.push(options)
end

class << Map
  src = 'options_for'
  %w( options opts extract_options ).each do |dst|
    alias_method(dst, src)
  end

  src = 'options_for!'
  %w( options! opts! extract_options! ).each do |dst|
    alias_method(dst, src)
  end

  src = 'update_options_for!'
  %w( update_options! update_opts! ).each do |dst|
    alias_method(dst, src)
  end
end

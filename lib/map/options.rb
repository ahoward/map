# -*- encoding : utf-8 -*-
class Map
  module Options
    class << Options
      def for(arg)
        options =
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

        unless options.is_a?(Options)
          options = Map.for(options)
          options.extend(Options)
        end

        raise unless options.is_a?(Map)

        options
      end

      def parse(arg)
        case arg
          when Array
            arguments = arg
            arguments.extend(Arguments) unless arguments.is_a?(Arguments)
            options = arguments.options
          when Hash
            options = arg
            options = Options.for(options)
          else
            raise(ArgumentError, "`arg` should be an Array or Hash")
        end
      end
    end

    attr_accessor :arguments

    def pop
      arguments.pop if arguments.last.object_id == object_id
      self
    end

    def popped?
      !(arguments.last.object_id == object_id)
    end

    def pop!
      arguments.pop if arguments.last.object_id == object_id
      self
    end

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
  end

  module Arguments
    def options
      @options ||=(
        if last.is_a?(Hash)
          options = Options.for(pop)
          options.arguments = self
          push(options)
          options
        else
          options = Options.for({})
          options.arguments = self
          options
        end
      )
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
  options = Map.options_for(args)
  block.call(options)
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

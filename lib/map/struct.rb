# -*- encoding : utf-8 -*-
class Map
  class Struct
    instance_methods.each { |m| undef_method m unless m =~ /^__|object_id/ }

    attr :map

    def initialize(map)
      @map = map
    end

    def method_missing(method, *args, &block)
      method = method.to_s
      case method
        when /=$/
          key = method.chomp('=')
          value = args.shift
          @map[key] = value
        when /\?$/
          key = method.chomp('?')
          value = @map.has?( key )
        else
          key = method
          raise(IndexError, key) unless @map.has_key?(key)
          value = @map[key]
      end
      value.is_a?(Map) ? value.struct : value
    end

    Keys = lambda{|*keys| keys.flatten!; keys.compact!; keys.map!{|key| key.to_s}} unless defined?(Keys)

    delegates = %w(
      inspect
    )

    delegates.each do |delegate|
      module_eval <<-__, __FILE__, __LINE__
        def #{ delegate }(*args, &block)
          @map.#{ delegate }(*args, &block)
        end
      __
    end
  end

  def struct
    @struct ||= Struct.new(self)
  end

  def Map.struct(*args, &block)
    new(*args, &block).struct
  end
end

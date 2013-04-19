class Map
  def param_for(*args, &block)
    options = Map.options_for!(args)

    prefix = options[:prefix] || 'map'

    src_key = args.flatten.map{|arg| Map.alphanumeric_key_for(arg)}

    dst_key = src_key.map{|k| k.is_a?(Numeric) ? 0 : k}

    src = self
    dst = Map.new

    value =
      if options.has_key?(:value)
        options[:value]
      else
        src.get(src_key).to_s
      end

    dst.set(dst_key, value)

    Param.param_for(dst, prefix)
  end

  def name_for(*args, &block)
    options = Map.options_for!(args)
    options[:value] = nil
    args.push(options)
    param_for(*args, &block)
  end

  def to_params
    to_params = Array.new

    depth_first_each do |key, val|
      to_params.push(param_for(key))
    end

    to_params.join('&')
  end

  module Param
    def param_for(value, prefix = nil)
      case value
        when Array
          value.map { |v|
            param_for(v, "#{ prefix }[]")
          }.join("&")

        when Hash
          value.map { |k, v|
            param_for(v, prefix ? "#{ prefix }[#{ escape(k) }]" : escape(k))
          }.join("&")

        when String
          raise ArgumentError, "value must be a Hash" if prefix.nil?
          "#{ prefix }=#{ escape(value) }"

        else
          prefix
      end
    end

    if(''.respond_to?(:bytesize))
      def bytesize(string) string.bytesize end
    else
      def bytesize(string) string.size end
    end

    require 'uri' unless defined?(URI)

    def escape(s)
      URI.encode_www_form_component(s)
    end

    extend(self)
  end
end

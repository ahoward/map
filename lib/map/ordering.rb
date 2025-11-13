# -*- encoding : utf-8 -*-

# Map::Ordering
#
# This module contains all ordering-related methods that use the @keys array
# to maintain insertion order. It is conditionally included in Map only when
# Ruby's Hash class does not maintain insertion order (Ruby < 1.9), or when
# explicitly forced via ENV['MAP_FORCE_ORDERING'].
#
# On Ruby 1.9+, Hash maintains insertion order natively, so these methods are
# not needed and Map delegates to Hash's implementation for memory optimization.

class Map < Hash
  module Ordering
    # Hook called when module is included into Map class
    # This allows us to inject class methods into Map
    def self.included(base)
      base.class_eval do
        # Override Map.allocate to initialize @keys array
        def self.allocate
          super.instance_eval do
            @keys = []
            self
          end
        end
      end
    end

    # Instance methods that track ordering via @keys array

    def keys
      @keys ||= []
    end

    def []=(key, val)
      key, val = convert(key, val)
      keys.push(key) unless has_key?(key)
      __set__(key, val)
    end
    alias_method 'store', '[]='

    def values
      array = []
      keys.each{|key| array.push(self[key])}
      array
    end
    alias_method 'vals', 'values'

    def first
      [keys.first, self[keys.first]]
    end

    def last
      [keys.last, self[keys.last]]
    end

    def each_with_index
      keys.each_with_index{|key, index| yield([key, self[key]], index)}
      self
    end

    def each_key
      keys.each{|key| yield(key)}
      self
    end

    def each_value
      keys.each{|key| yield self[key]}
      self
    end

    def each
      keys.each{|key| yield(key, self[key])}
      self
    end
    alias_method 'each_pair', 'each'

    def delete(key)
      key = convert_key(key)
      keys.delete(key)
      super(key)
    end

    def clear
      keys.clear
      super
    end

    # Array-like ordered operations
    def shift
      unless empty?
        key = keys.first
        val = delete(key)
        [key, val]
      end
    end

    def unshift(*args)
      Map.each_pair(*args) do |key, val|
        key = convert_key(key)
        delete(key)
        keys.unshift(key)
        __set__(key, val)
      end
      self
    end

    def push(*args)
      Map.each_pair(*args) do |key, val|
        key = convert_key(key)
        delete(key)
        keys.push(key)
        __set__(key, val)
      end
      self
    end

    def pop
      unless empty?
        key = keys.last
        val = delete(key)
        [key, val]
      end
    end
  end
end

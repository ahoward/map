require 'core_ext'

module ActiveRecord
  class Base
    NAMES = %w(
      Dog
      DogWalker
    )

    def self.column_names
      %w(
        id
        name
      )
    end

    def self.name
      NAMES[ rand( 50 ) % 2 ]
    end

    def self.reflections
      {
        :r1 => Reflection.new,
        :r2 => Reflection.new( true )
      }
    end

    def initialize( *args , &block )
      options = Map.opts args
      @has_relations = options.has_relations rescue args.first || false
    end

    def bogus
      'wut'
    end

    def id
      rand 10000
    end

    def name
      inspect
    end

    def r1
      return nil unless @has_relations
      self.class.new
    end

    def r2
      return [] unless @has_relations
      [ self.class.new , self.class.new ]
    end

    def reflections
      self.class.reflections
    end

    class Reflection
      def initialize( is_collection = false )
        @is_collection = is_collection
      end

      def collection?
        @is_collection
      end
    end
  end
end

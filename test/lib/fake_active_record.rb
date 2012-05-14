module ActiveRecord
  class Base
    def attributes
      { :k1 => 'v1' , :k2 => 'v2' }
    end

    def r1
      Association.new
    end

    def r2
      [ Association.new , Association.new ]
    end

    def reflections
      {
        :r1 => Reflection.new,
        :r2 => Reflection.new( true )
      }
    end

    class Association
      def attributes
        { :ak1 => 'v1' , :ak2 => 'v2' }
      end
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

# -*- encoding : utf-8 -*-
class Map
  module Integrations
    module ActiveRecord
      def to_map( include_related = false )
        attrs = attributes.dup

        reflections.each do | key , reflection |
          associated = send key
          attrs[ key ] = case
                           when reflection.collection?
                             associated.map { | related | related.attributes }
                           else
                             associated.attributes
                         end
        end if include_related

        Map.for attrs
      end
    end
  end
end

if defined?( ActiveRecord::Base )
  ActiveRecord::Base.send( :include , Map::Integrations::ActiveRecord )
end

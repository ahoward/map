# -*- encoding : utf-8 -*-
class Map
  module Integrations
    module ActiveRecord
      def self.included( klass )
        klass.extend ClassMethods
      end

      module ClassMethods
        def to_map( record , *args )
          # prep
          model         = record.class
          map           = Map.new
          map[ :model ] = model.name.underscore
          map[ :id ]    = record.id

          # yank out options if they are patently obvious...
          if args.size == 2 and args.first.is_a?( Array ) and args.last.is_a?( Hash )
            options = Map.for args.last
            args = args.first
          else
            options = nil
          end

          # get base to_dao from class
          base = column_names

          # available options keys
          opts = %w( include includes with exclude excludes without )

          # proc to remove options
          extract_options =
            proc do |array|
              to_return = Map.new
              last = array.last
              if last.is_a?( Hash )
                last = Map.for last
                if opts.any? { | opt | last.has_key? opt }
                  array.pop
                  to_return = last
                end
              end
              to_return
            end

          # handle case where options are bundled in args...
          options ||= extract_options[args]

          # use base options iff none provided
          base_options = extract_options[base]
          if options.blank? and !base_options.blank?
            options = base_options
          end

          # refine the args with includes iff found in options
          include_opts = [ :include , :includes , :with ]
          if options.any? { | option | include_opts.include? option.to_sym }
            args.replace( base ) if args.empty?
            args.push( options[ :include ] )  if options[ :include ]
            args.push( options[ :includes ] ) if options[ :includes ]
            args.push( options[ :with ] )     if options[ :with ]
          end

          # take passed in args or model defaults
          list = args.empty? ? base : args
          list = column_names if list.empty?

          # proc to ensure we're all mapped out
          map_nested =
            proc do | value , *args |
              if value.is_a?( Array )
                value.map { | v | map_nested[ v , *args ] }
              else
                if value.respond_to? :to_map
                  value.to_map *args
                else
                  value
                end
              end
            end

          # okay - go!
          list.flatten.each do | attr |
            if attr.is_a?( Array )
              related , *argv = attr
              v = record.send related
              value = map_nested[ value , *argv ]
              map[ related ] = value
              next
            end

            if attr.is_a?( Hash )
              attr.each do | related , argv |
                v = record.send related
                argv = !argv.is_a?( Array ) ? [ argv ] : argv
                value = map_nested[ v , *argv ]
                map[ related ] = value
              end
              next
            end

            value = record.send attr

            if value.respond_to?( :to_map )
              map[ attr ] = value.to_map
              next
            end

            if value.is_a?( Array )
              map[ attr ] = value.map &map_nested
              next
            end

            map[ attr ] = value
          end

          # refine the map with excludes iff passed as options
          exclude_opts = [ :exclude , :excludes , :without ]
          if options.any? { | option | exclude_opts.include? option.to_sym }
            [ options[ :exclude ] , options[ :excludes ] , options[ :without ] ].each do | paths |
              paths = Array paths
              next if paths.blank?
              paths.each { | path | map.rm path }
            end
          end

          map
        end
      end

      def to_map( *args )
        self.class.to_map self , *args
      end
    end
  end
end

if defined?( ActiveRecord::Base )
  ActiveRecord::Base.send :include , Map::Integrations::ActiveRecord
end

module Depix
  class Structdef
    class << self
      ALLOWED_OPTIONS = [:desc, :req]
      DEFAULT_OPTIONS = {:desc => 'Value', :req => false}

      # To avoid fucking up with sizes afterwards
      U32, R32, U16, U8, UCHAR = 4, 4, 2, 1, 1
      
      def u32(name, *extras)
        count, options = count_and_opts_from(extras)
        add_field(name, "A#{count}")
      end

      def u16(name, *extras)
        count, options = count_and_opts_from(extras)
        add_field(name, "V#{count}") # ????
      end

      def u8(name, *extras)
        count, options = count_and_opts_from(extras)
        add_field(name, "c#{count}") # ????
      end
      
      def r32(name, *extras)
        count, options = count_and_opts_from(extras)
        add_field(name, "g")
      end

      def char(name, *extras)
        count, options = count_and_opts_from(extras)
        add_field(name, "C#{count}")
      end

      def inner(name, mapping, options = {})
        add_field_with_cast(name, mapping)
      end

      def array(name, mapping_for_member, *extras)
        count, options = count_and_opts_from(extras)
        (0...count).each do |i|
          inner_name = [name, i].join('.')
          
          if mapping_for_member.is_a?(Class)
            add_field_with_cast(inner_name, mapping_for_member)
          else
            send(mapping_for_member,  inner_name)
          end
        end
      end
      
      
      def to_template
        @template.join
      end
      
      def mapping
        @keys.map{| f | "#{f}" }
      end
      
      def inspect
        "%s (%s)" % [super, mapping.join(', ')]
      end
      
      private
        def count_and_opts_from(args)
          options = if args[-1].is_a?(Hash)
            DEFAULT_OPTIONS.merge(args.pop)
          else
            DEFAULT_OPTIONS
          end
          count = args.shift || 1
          
          [count, options]
        end
        
        def add_field(name, template)
          init_table
          
          @keys << name
          @template << template
        end

        def add_field_with_cast(name, cast_class)
          init_table
          
          @casts[name] = cast_class
          add_field(name, cast_class.to_template)
        end

        def init_table
          @keys ||= []
          @template ||= []
          @casts ||= {}
        end
    end
  end
end
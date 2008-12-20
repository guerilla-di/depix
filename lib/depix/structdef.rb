module Depix
  class Structdef
    class << self
      ALLOWED_OPTIONS = [:desc, :req]
      DEFAULT_OPTIONS = {:desc => 'Value', :req => false}

      # To avoid fucking up with sizes afterwards
      U32, R32, U16, U8, UCHAR = 4, 4, 2, 1, 1

      # Define an unsigned 32bit integer
      def u32(name, *extras)
        count, options = count_and_opts_from(extras)
        add_key(name, "N#{count}")
      end
      
      # Define an unsigned 16bit integer
      def u16(name, *extras)
        count, options = count_and_opts_from(extras)
        add_key(name, "V#{count}") # ????
      end

      # Define an unsigned 8bit int
      def u8(name, *extras)
        count, options = count_and_opts_from(extras)
        add_key(name, "c#{count}") # ????
      end

      # Define an unsigned 32bit float
      def r32(name, *extras)
        count, options = count_and_opts_from(extras)
        add_key(name, "g")
      end

      # Define a char
      def char(name, *extras)
        count, options = count_and_opts_from(extras)
        add_key(name, "C#{count}")
      end

      def inner(name, mapping, options = {})
        add_key_with_cast(name, mapping)
      end

      def array(name, mapping_for_member, *extras)
        count, options = count_and_opts_from(extras)
        (0...count).each do |i|
          inner_name = [name, i].join('.')
          
          if mapping_for_member.is_a?(Class)
            add_key_with_cast(inner_name, mapping_for_member)
          else
            send(mapping_for_member,  inner_name)
          end
        end
      end
      
      # See the fields that this struct defines
      def inspect
        "%s (%s)" % [super, keys.join(', ')]
      end
      
      # Apply this struct template to a string, filling the value slots. Will return an instance.
      def apply_to_string(to_string)
        # The idea is as follows. When we unpack, we get an array of fixed length. We can use the
        # indices in this array to fill in the slots
        values = to_string.unpack(to_template)
        keys.each 
      end
      
      # Apply to unpacked values
      def apply_to_values(value_array)
      end
      
      # Returns the keys, ordered by their position in the struct. Nested keys will included
      # as well
      def keys
        @keys ||= []
      end
      
      # Convert the struct and all it's nested structs to one pack template
      def template
        @template ||= ''
      end
      alias_method :to_template, :template
      
      def casts
        @casts ||= {}
      end
      
      # How many bytes this struct would occupy. Can be used to read only that many bytes
      def byte_length
        size_map = {"C" => 1, "c" => 1, "N" => 4, "n" => 1, "v" => 1, "g" => 4, "V" => 2 }
        template.gsub(/(\w)(\d+)/) { '.' * (size_map[$1] * $2.to_i) }.length
      end

      # Freezes the struct definition, all inner values will be cached
      def bake!
      end
      
      private
        # extract_options! on a diet
        def count_and_opts_from(args)
          options = args[-1].is_a?(Hash) ? DEFAULT_OPTIONS.merge(args.pop) : DEFAULT_OPTIONS
          count = args.shift || 1
          [count, options]
        end
        
        def add_key(name, template)
          keys << name.to_s
          template << template
        end

        def add_key_with_cast(name, cast_class)
          casts[name] = cast_class
          add_key(name, cast_class.to_template)
        end
        
    end
  end
end
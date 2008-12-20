module Depix
  class Fields
    ALLOWED_OPTIONS = [:desc, :req]
    DEF_OPTS = {:desc => 'Value', :req => false}
    PACKERS = { :u32 => "N", :char => "C", :u16 => "n", :u8 => "c", :r32 => "g" }
    
    class << self

      # Define an unsigned 32bit integer
      def u32(name, *extras)
        count, options = count_and_opts_from(extras)
        # Discard count here because otherwise it will be an array
      end
      
      # Define an unsigned 16bit integer
      def u16(name, *extras)
        count, options = count_and_opts_from(extras)
        # Discard count here because otherwise it will be an array
      end

      # Define an unsigned 8bit int
      def u8(name, *extras)
        count, options = count_and_opts_from(extras)
        # Discard count here because otherwise it will be an array
      end

      # Define an unsigned 32bit float
      def r32(name, *extras)
        count, options = count_and_opts_from(extras)
        # Discard count here because otherwise it will be an array
      end

      # Define a char
      def char(name, *extras)
        count, options = count_and_opts_from(extras)
        # Here we will use count to set string length
      end
      
      # Define an inner structure
      def inner(name, mapping, options = {})
        
      end

      # Define an array of values
      def array(name, mapping_for_member, *extras)
      
      end
      
      # See the fields that this struct defines
      def inspect
        "%s (%s)" % [super, keys.join(', ')]
      end
      
      # How many bytes this struct would occupy. Can be used to read only that many bytes
      def byte_length
        size_map = {"C" => 1, "c" => 1, "N" => 4, "n" => 1, "v" => 1, "g" => 4, "V" => 2 }
        template.gsub(/(\w)(\d+)/) { '.' * (size_map[$1] * $2.to_i) }.length
      end
      
      private
        # extract_options! on a diet
        def count_and_opts_from(args)
          options = args[-1].is_a?(Hash) ? DEF_OPTS.merge(args.pop) : DEF_OPTS
          count = args.shift || 1
          [count, options]
        end
        
    end
  end
end
module Depix
  
  class Field
    attr_accessor :name, :length, :pattern, :req, :desc
    alias_method :req?, :req

    def initialize(opts = {})
      opts.each_pair {|k, v| send(k.to_s + '=', v) }
    end

    # Emit an unsigned int field
    def self.emit_u32(o = {})
      new({:length => 4, :pattern => "N" }.merge(o))
    end
    
    # Emit a short int field
    def self.emit_u8(o = {})
      new({:length => 1, :pattern => "c" }.merge(o))
    end

    # Emit a double int field
    def self.emit_u16(o = {})
      new({:length => 2, :pattern => "n" }.merge(o))
    end
    
    # Emit a char field
    def self.emit_char(o = {})
      opts = {:length => 1}.merge(o)
      opts[:pattern] = "A#{opts[:length].to_i}"
      new(opts)
    end
    
    # Emit a float field
    def self.emit_r32(o = {})
      new o.merge({:length => 4, :pattern => "g"})
    end
    
    # Return the actual values from the stack. The stack will begin on the element we need,
    # so the default consumption is shift
    def consume!(stack)
      stack.shift
    end
  end
  
  class ArrayField < Field
    attr_accessor :members
    undef :length=, :pattern=
    
    def length
      members.inject(0){|_, s| _ + s.length }
    end
    
    def pattern
      members.inject(''){|_, s| _ + s.pattern }
    end
    
    def consume!(stack)
      members.map{|m| m.consume!(stack)}
    end
  end
  
  class InnerField < Field
    attr_accessor :cast
    undef :length=, :pattern=
    
    def length
      cast.length
    end
    
    def pattern
      cast.pattern
    end
    
    def consume!(stack)
      cast.consume!(stack)
    end
  end
  
  class Dict
    DEF_OPTS = { :req => false, :desc => nil }
    
    class << self
      
      def fields
        @fields ||= []
      end
      
      def u32(name, *extras)
        count, opts = count_and_opts_from(extras)
        attr_accessor name
        fields << Field.emit_u32( {:name => name }.merge(opts) )
      end

      def u16(name, *extras)
        count, opts = count_and_opts_from(extras)
        attr_accessor name
        fields << Field.emit_u16( {:name => name }.merge(opts) )
      end

      def u8(name, *extras)
        count, opts = count_and_opts_from(extras)
        attr_accessor name
        fields << Field.emit_u8( {:name => name }.merge(opts) )
      end

      def r32(name, *extras)
        count, opts = count_and_opts_from(extras)
        attr_accessor name
        fields << Field.emit_r32( {:name => name}.merge(opts) )
      end
      
      def array(name, mapped_to, *extras)
        count, opts = count_and_opts_from(extras)
        attr_accessor name
        
        a = ArrayField.new({:name => name}.merge(opts))
        a.members = if mapped_to.is_a?(Class) # Array of structs
          [InnerField.new(:cast => mapped_to)] * count
        else
          [Field.send("emit_#{mapped_to}")] * count
        end
        fields << a
      end
      
      def inner(name, mapped_to, *extras)
        count, opts = count_and_opts_from(extras)
        attr_accessor name
        fields << InnerField.new({:name => name, :cast => mapped_to}.merge(opts))
      end
      
      def char(name, *extras)
        count, opts = count_and_opts_from(extras)
        attr_accessor name
        fields << Field.emit_char( {:name => name, :length => count}.merge(opts) )
      end
      
      def pattern
        fields.map{|f| f.pattern }.join
      end
      
      def length
        fields.inject(0){|_, s| _ + s.length }
      end
      
      def consume!(stack_of_unpacked_values)
        new_item = new
        @fields.each do | field |
          new_item.send("#{field.name}=", field.consume!(stack_of_unpacked_values))
        end
        new_item
      end
      
      def apply!(string)
        consume!(string.unpack(pattern))
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
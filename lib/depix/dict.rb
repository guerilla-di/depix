module Depix
  
  #:stopdoc:
  class Field
    attr_accessor :name, :length, :pattern, :req, :desc, :rtype
    alias_method :req?, :req
    
    # Hash init
    def initialize(opts = {})
      opts.each_pair {|k, v| send(k.to_s + '=', v) }
    end

    # Emit an unsigned int field
    def self.emit_u32(o = {})
      U32Field.new(o)
    end
    
    # Emit a short int field
    def self.emit_u8(o = {})
      U8Field.new(o)
    end

    # Emit a double int field
    def self.emit_u16(o = {})
      U16Field.new(o)
    end
    
    # Emit a char field
    def self.emit_char(o = {})
      opts = {:length => 1}.merge(o)
      CharField.new(opts)
    end
    
    # Emit a float field
    def self.emit_r32(o = {})
      R32Field.new(o)
    end
    
    # Return a cleaned value
    def clean(v)
      v
    end
    
    def explain
      [rtype ? ("(%s)" % rtype) : nil, desc, (req? ? "- required" : nil)].compact.join(' ')
    end
    
    # Return the actual values from the stack. The stack will begin on the element we need,
    # so the default consumption is shift
    def consume!(stack)
      clean(stack.shift)
    end
  end
  
  class U32Field < Field
    BLANK = 0xFFFFFFFF
    
    def pattern
      "N"
    end
    
    def length
      4
    end
    
    def clean(value)
      value == BLANK ? nil : value
    end
  end
  
  class U8Field < Field

    BLANK = 0xFF

    def pattern
      "c"
    end
    
    def length
      1
    end
    
    def rtype
      Integer
    end
    
    def clean(v)
      v == BLANK ? nil : v
    end
  end
  
  class Filler < Field
    def pattern
      "a#{length.to_i}"
    end
    
    def clean(v)
      nil
    end
    
    def consume(stack)
      stack.shift
      nil
    end
  end
    
  class U16Field < Field
    BLANK = 0xFFFF
    
    def pattern
      "n"
    end
    
    def length
      2
    end
    
    def rtype
      Integer
    end
    
    def clean(v)
      v == BLANK ? nil : v
    end
  end
  
  class R32Field < Field
    def pattern
      "g"
    end
    
    def clean(v)
      v.nan? ? nil : v
    end
    
    def length
      4
    end
    
    def rtype
      Float
    end
  end
  
  class CharField < Field
    def pattern
      "A#{(length || 1).to_i}"
    end
    
    def clean(v)
      begin
        v.gsub(0xFF.chr, '').gsub(0x00.chr, '')
      rescue NoMethodError
        v
      end
    end
    
    def rtype
      String
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
    
    def rtype
      Array
    end
    
    def explain
      return 'Empty array' if (!members || members.empty?)
      tpl = "(Array of %d %s fields)" % [ members.length, members[0].rtype]
      r = (req? ? "- required" : nil)
      [tpl, desc, r].compact.join(' ')
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
    
    def rtype
      cast
    end
  end
  
  # Base class for a struct. Could also be implemented as a module actually
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
      
      # Consume a stack of unpacked values, letting each field decide how many to consume
      def consume!(stack_of_unpacked_values)
        new_item = new
        @fields.each do | field |
          new_item.send("#{field.name}=", field.consume!(stack_of_unpacked_values)) unless field.name.nil?
        end
        new_item
      end
      
      def apply!(string)
        consume!(string.unpack(pattern))
      end
      
      # Get a class that would parse just the same, preserving only the fields passed in the array. This speeds
      # up parsing because we only extract and conform the fields that we need
      def only(*field_names)
        distillate = fields.inject([]) do | m, f |
          if field_names.include?(f.name) # preserve
            m.push(f)
          else # create filler
            unless m[-1].is_a?(Filler)
              m.push(Filler.new(:length =>  f.length))
            else
              m[-1].length += f.length
            end
            m
          end
        end
        
        anon = Class.new(self)
        anon.fields.replace(distillate)
        anon
      end
      
      def filler
        only([])
      end
      
      private

      # extract_options! on a diet
      def count_and_opts_from(args)
        options, count = (args[-1].is_a?(Hash) ? DEF_OPTS.merge(args.pop) : DEF_OPTS), (args.shift || 1)
        [count, options]
      end
    end
  end
  
  #:startdoc:
end
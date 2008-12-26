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
    
    # Check that the passed value:
    # a) Matches the Ruby type expected
    # b) Fits into the slot
    # c) Does not overflow
    # When the validation fails should raise
    def validate!(value)
      raise "#{name} value required, but got nil in #{name}".strip if value.nil? && req?
      raise "Value expected to be #{rtype} but was #{value.class}" if !value.nil? && rtype && !value.is_a?(rtype)
    end
    
    # Pack a value passed into a string
    def pack(value)
      raise "No pattern defined for #{self}" unless pattern
      if value.nil?
        [self.class.const_get(:BLANK)].pack(pattern)
      else
        [value].pack(pattern)
      end
    end
  end
  
  class U32Field < Field
    BLANK = 0xFFFFFFFF
    undef :length=, :pattern=
    
    def pattern
      "N"
    end
    
    def length
      4
    end
    
    def clean(value)
      value == BLANK ? nil : value
    end
    
    # Override - might be Bignum although cast to Integer sometimes
    def validate!(value)
      raise "#{name} value required, but got nil".strip if value.nil? && req?
      raise "#{name} value expected to be #{rtype} but was #{value.class}" if !value.nil? && (!value.is_a?(Integer) && !value.is_a?(Bignum))
      raise "#{name} value #{value} overflows" if !value.nil? && (value < 0 || value >= BLANK)
    end
    
  end
  
  class U8Field < Field
    undef :length=, :pattern=

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
      (v == BLANK || v == -1) ? nil : v
    end
    
    def validate!(value)
      super(value)
      raise "#{name} value #{value} out of bounds for 8 bit unsigned int".lstrip if (!value.nil? && (value < 0 || value >= BLANK))
    end
  end
  
  class Filler < Field
    undef :pattern=
    def pattern
      "x#{length ? length.to_i : 1}"
    end
    
    # Leave the stack alone since we skipped
    def consume(stack)
      nil
    end
    
    def pack(data)
      raise "This is a filler, it cannot be reconstructed from a value"
    end
  end
    
  class U16Field < Field
    BLANK = 0xFFFF
    undef :length=, :pattern=
    
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
    
    def validate!(value)
      super(value)
      raise "#{name} value #{value} out of bounds for 16bit unsigned int" if (value < 0 || value >= BLANK)
    end
  end
  
  class R32Field < Field
    undef :length=, :pattern=
    BLANK = 0xFFFFFFFF
    
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
    BLANK = "\0"
    undef :pattern=
    
    BLANKING_VALUES = [0x00.chr, 0xFF.chr]
    BLANKING_PATTERNS = BLANKING_VALUES.inject([]) do | p, char |
      p << /^(#{char}+)/ << /(#{char}+)$/
    end
    
    def pattern
      "A#{(length || 1).to_i}"
    end
    
    def clean(v)
      if v == BLANK
        nil
      else
        2.times { BLANKING_PATTERNS.each{|p| v.gsub!(p, '')} }
        v.empty? ? nil : v
      end
    end
    
    def rtype
      String
    end
    
    def validate!(value)
      super(value)
      raise "#{value} overflows the #{length} bytes allocated" if !value.nil? && value.length > length
    end
    
    def pack(value)
      value.ljust(length, "\000") rescue ("\000" * length)
    end
  end
  
  # Wrapper for an array structure
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
    
    def validate!(array)
      raise "This value would overflow, #{array.length} elements passed but only #{members.length} fit" unless array.length <= members.length
      raise "This value is required, but the array is empty" if req? && array.empty?
      array.zip(members).map do | v, m | 
        m.validate!(v) unless (v.nil? && !m.req?)
      end
    end
    
    def pack(values)
      # For members that are present, get values. For members that are missing, fill with null bytes upto length.
      # For values that are nil, skip packing
      members.zip(values).map do |m, v| 
        if !m.req? && v.nil?
          raise "#{m} needs to provide length" unless m.length
          "\377" * m.length
        else
          v.respond_to?(:pack) ? v.pack : m.pack(v)
        end
      end.join
    end
  end
  
  # Wrapper for a contained structure
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
    
    def validate!(value)
      super(value)
      cast.validate!(value) if cast.respond_to?(:validate!) && (!value.nil? || req?)
    end
    
    def pack(value)
      cast.pack(value)
    end
  end
  
  # Base class for a struct. Could also be implemented as a module actually
  class Dict
    DEF_OPTS = { :req => false, :desc => nil }
    
    class << self
      
      # Get the array of fields defined in this struct
      def fields
        @fields ||= []
      end
      
      # Validate a passed instance
      def validate!(instance)
        fields.each do | f |
          f.validate!(instance.send(f.name)) if f.name
        end
      end
      
      # Define a 4-byte unsigned integer
      def u32(name, *extras)
        count, opts = count_and_opts_from(extras)
        attr_accessor name
        fields << Field.emit_u32( {:name => name }.merge(opts) )
      end

      # Define a double-width unsigned integer
      def u16(name, *extras)
        count, opts = count_and_opts_from(extras)
        attr_accessor name
        fields << Field.emit_u16( {:name => name }.merge(opts) )
      end


      # Define a small unsigned integer
      def u8(name, *extras)
        count, opts = count_and_opts_from(extras)
        attr_accessor name
        fields << Field.emit_u8( {:name => name }.merge(opts) )
      end

      # Define a real number
      def r32(name, *extras)
        count, opts = count_and_opts_from(extras)
        attr_accessor name
        fields << Field.emit_r32( {:name => name}.merge(opts) )
      end

      # Define an array of values
      def array(name, mapped_to, *extras)
        count, opts = count_and_opts_from(extras)
        attr_accessor name
        
        a = ArrayField.new({:name => name}.merge(opts))
        a.members = if mapped_to.is_a?(Class) # Array of structs
          [InnerField.new(:cast => mapped_to)] * count
        else
          [Field.send("emit_#{mapped_to}")] * count
        end
        yield a.members if block_given?
        fields << a
      end
      
      # Define a nested struct
      def inner(name, mapped_to, *extras)
        count, opts = count_and_opts_from(extras)
        attr_accessor name
        fields << InnerField.new({:name => name, :cast => mapped_to}.merge(opts))
      end
      
      # Define a char field
      def char(name, *extras)
        count, opts = count_and_opts_from(extras)
        attr_accessor name
        fields << Field.emit_char( {:name => name, :length => count}.merge(opts) )
      end
      
      # Get the pattern that will be used to unpack this structure and all of it's descendants
      def pattern
        fields.map{|f| f.pattern }.join
      end
      
      # How many bytes are needed to complete this structure
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
      
      # Apply this structure to data in the string, returning an instance of this structure with fields completed
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
        only_items = distillate.map{|n| n.name }
        
        anon
      end
      
      # Get an opaque struct based on this one, that will consume exactly as many bytes as this
      # structure would occupy, but discard them instead
      def filler
        only([])
      end
      
      # Pack the instance of this struct
      def pack(instance, buffer = nil)
        
        # Preallocate a buffer just as big as me since we want everything to remain at fixed offsets
        buffer ||= ("\000" * length)
        
        # If the instance is nil return pure padding
        return buffer if instance.nil?
        
        # Now for the important stuff. For each field that we have, replace a piece at offsets in the buffer
        # with the packed results, skipping fillers
        fields.each_with_index do | f, i |
          
          # Skip blanking, we just dont touch it. TODO - test!
          next if f.is_a?(Filler)
          
          # Where should we put that value?
          offset = fields[0...i].inject(0){|_, s| _ + s.length }

          val = instance.send(f.name)

          # Validate the passed value using the format the field supports
          f.validate!(val)
          
          packed = f.pack(val)
          
          # Signal offset violation
          raise "Improper length for #{f.name} - packed #{packed.length} bytes but #{f.length} is required to fill the slot" if packed.length != f.length

          buffer[offset...(offset+f.length)] = packed
        end
        raise "Resulting buffer not the same length, expected #{length} bytes but compued #{buffer.length}" if buffer.length != length
        buffer
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
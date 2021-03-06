# coding: ASCII-8BIT
module Depix; module Binary; module Fields
  
  # Base class for a padded field in a struct
  class Field
    attr_accessor :name # Field name
    attr_accessor :length # Field length in bytes, including any possible padding
    attr_accessor :pattern # The unpack pattern that defines the field
    attr_accessor :req # Is the field required?
    attr_accessor :desc # Field description
    attr_accessor :rtype  # To which Ruby type this has to be cast (and which type is accepted as value)
    
    alias_method :req?, :req
    
    # Hash init
    def initialize(opts = {})
      opts.each_pair {|k, v| send(k.to_s + '=', v) }
    end
    
    # Return a cleaned value (like a null-terminated string truncated up to null)
    def clean(v)
      v
    end
    
    # Show a nice textual explanation of the field
    def explain
      [rtype ? ("(%s)" % rtype) : nil, desc, (req? ? "- required" : nil)].compact.join(' ')
    end
    
    # Return the actual values from the stack. The stack will begin on the element we need,
    # so the default consumption is shift. Normally all fields shift the stack
    # as they go, and if they contain nested substructs they will pop the stack as well
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
    
    private
    def blanking?(blob)
      blob.nil? || blob.empty? || blob == (0xFF.chr * length)
    end
  end
  
  # unit32 field
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
  
  # uint8 field
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
  
  # Zero-padded filler, can be used to maintain offsets
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
    
  # uint16 field
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
      (v == BLANK || v == -1) ? nil : v
    end
    
    def validate!(value)
      super(value)
      raise "#{name} value #{value} out of bounds for 16bit unsigned int" if (value < 0 || value >= BLANK)
    end
    
  end
  
  # real32 field. Now, there is some lap dancing to be done here.
  # The DPX files in the wild define nonexistant data as a charfield with all
  # it's bits set (four times 0xFF byte). This is easy to verify with a string
  # but practically useless once the charfield has been unpacked into a float.
  # Therefore we first unpack the value as a charfield, then we check whether it's all
  # blanking, and if it is we return nil. If it's not "all bits set" though what we will do
  # is try to decode it again using the real float unpack pattern. The same dance
  # happens reciprocally when repacking the data.
  class R32Field < Field
    undef :length=, :pattern=
    BLANK = (0xFF.chr * 4)
    PATTERN_BE = "g"
    PATTERN_LE = "n"
    
    def pattern
      "g"
    end
    
    def clean(v)
      (v.nil? || v.nan?) ? nil : v
    end
    
    def length
      4
    end
    
    def rtype
      Float
    end
    
    # The packing of NaN
    # [12] pry(main)> value = 0 / 0.0
    # => NaN
    # [13] pry(main)> [value].pack("g")
    # => "\xFF\xC0\x00\x00"
    # [14] pry(main)> [value].pack("g")
    def pack(value)
      (value.nil? || value.nan? ) ? BLANK : [value].pack("g")
    end
  end
  
  # null-terminated string field with fixed padding
  class CharField < Field
    undef :pattern=
    
    def initialize(opts = {})
      super({:length => 1}.merge(opts))
    end
    
    def pattern
      "Z#{length}"
    end
    
    def clean(v)
      # Use the pack->unpack trick to remove null-termination
      v = pack(v.to_s).unpack(pattern)[0]
      # Blanked fields are 0xFF all the way
      blanking?(v) ? nil : v
    end
    
    def rtype
      String
    end
    
    def validate!(value)
      super(value)
      raise "#{value} overflows the #{length} bytes allocated" if !value.nil? && value.length > length
    end
    
    def pack(value)
      unless blanking?(value)
        [value].pack(pattern)
      else
        0xFF.chr * length
      end
    end
  end
  
  # For reserved fields and blanking 
  class BlankingField < CharField
    
    def validate!(value)
      raise "The value of this field should be nil" unless value.nil?
    end
    
    def pattern
      "Z#{length}"
    end
    
    def clean(v)
      nil
    end
    
    def rtype
      NilClass
    end
    
    def pack(value)
      0xFF.chr * length
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
end; end; end
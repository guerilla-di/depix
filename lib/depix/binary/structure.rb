# A basic C structs library (only works by value).
# Here's the basic mode of operation:
#  1) You define a struct, with a number of fields in it. This hould be a subclass of Dict within which you
#     create Field objects which are saved in a class variable
#  3) Each created Field instance knows how big it is and how to produce a pattern to get it's value from the byte stream
#     by using Ruby's "pack/unpack". Each field thus provides an unpack pattern, and patterns are ordered
#     into a stack, starting with the first unpack pattern
#  4) When you parse some bytes using the struct:
#     - An unpack pattern will be compiled from all of the fields composing the struct,
#      and it will be a single string. The string gets applied to the bytes passed to parse()
#     - An array of unpacked values returned by unpack is then passed to the struct's consumption engine,
#       which lets each field take as many items off the stack as it needs. A field might happily produce
#       4 items for unpacking and then take the same 4 items off the stack of parsed values. Or not.
#     - A new structure gets created and for every named field it defines an attr_accessor. When consuming,
#       the values returned by Field objects get set using the accessors (so accessors can be overridden too!)
#  5) When you save out the struct roughly the same happens but in reverse (readers are called per field,
#     then it's checked whether the data can be packed and fits into the alloted number of bytes, and then
#     one big array of values is composed and passed on to Array#pack)
# 
# For example
# 
#  class OneIntegerAndOneFloat < Structure
#    uint32 :identifier, :description => "This is the important ID", :required => true
#    real :value, :description => "The value that we store"
#  end
#  
#  ready_struct = OneIntegerAndOneFloat.new
#  ready_struct.identifier = 23 # Plain Ruby assignment
#  ready_struct.value = 45.0
#  
#  binary_file.write(OneIntegerAndOneFloat.pack(ready_struct)) # dumps the packed struct with paddings
class Depix::Binary::Structure
  
  DEF_OPTS = { :req => false, :desc => nil }
  
  # Allows us to use field names from Fields module
  def self.const_missing(c)
    Depix::Binary::Fields.const_get(c)
  end
  
  # Get the array of fields defined in this struct
  def self.fields
    @fields ||= []
  end
  
  # Validate a passed instance
  def self.validate!(instance)
    fields.each do | f |
      f.validate!(instance.send(f.name)) if f.name
    end
  end
  
  # Define a 4-byte unsigned integer
  def self.u32(name, *extras)
    count, opts = count_and_opts_from(extras)
    attr_accessor name
    fields << U32Field.new( {:name => name }.merge(opts) )
  end

  # Define a double-width unsigned integer
  def self.u16(name, *extras)
    count, opts = count_and_opts_from(extras)
    attr_accessor name
    fields << U16Field.new( {:name => name }.merge(opts) )
  end
  
  # Define a blanking field (it's return value is always nil)
  def self.blanking(name, *extras)
    length, opts = count_and_opts_from(extras)
    attr_accessor name
    fields << BlankingField.new( {:name => name, :length => length}.merge(opts) )
  end
  
  # Define a small unsigned integer
  def self.u8(name, *extras)
    count, opts = count_and_opts_from(extras)
    attr_accessor name
    fields << U8Field.new( {:name => name }.merge(opts) )
  end

  # Define a real number
  def self.r32(name, *extras)
    count, opts = count_and_opts_from(extras)
    attr_accessor name
    fields << R32Field.new( {:name => name}.merge(opts) )
  end

  # Define an array of values
  def self.array(name, mapped_to, *extras)
    count, opts = count_and_opts_from(extras)
    attr_accessor name
    a = ArrayField.new({:name => name}.merge(opts))
    a.members = if mapped_to.is_a?(Class) # Array of structs
      [InnerField.new(:cast => mapped_to)] * count
    else
      c = Depix::Binary::Fields.const_get("#{mapped_to.to_s.upcase}Field")
      [c.new] * count
    end
    yield a.members if block_given?
    fields << a
  end
  
  # Define a nested struct
  def self.inner(name, mapped_to, *extras)
    count, opts = count_and_opts_from(extras)
    attr_accessor name
    fields << InnerField.new({:name => name, :cast => mapped_to}.merge(opts))
  end
  
  # Define a char field
  def self.char(name, *extras)
    count, opts = count_and_opts_from(extras)
    attr_accessor name
    fields << CharField.new( {:name => name, :length => count}.merge(opts) )
  end
  
  # Get the pattern that will be used to unpack this structure and all of it's descendants
  def self.pattern
    fields.map{|f| f.pattern }.join
  end
  
  # Get the pattern that will be used to unpack this structure and all of it's descendants
  # from a buffer with pieces in little-endian byte order
  def self.pattern_le
    pattern.tr("gN", "eV")
  end
  
  # How many bytes are needed to complete this structure
  def self.length
    fields.inject(0){|_, s| _ + s.length.to_i }
  end
  
  # Consume a stack of unpacked values, letting each field decide how many to consume
  def self.consume!(stack_of_unpacked_values)
    new_item = new
    @fields.each do | field |
      new_item.send("#{field.name}=", field.consume!(stack_of_unpacked_values)) unless field.name.nil?
    end
    new_item
  end
  
  # Apply this structure to data in the string, returning an instance of this structure with fields completed
  def self.apply!(string)
    consume!(string.unpack(pattern))
  end
  
  # Apply this structure to data in the string, returning an instance of this structure with fields completed
  # assume little-endian fields
  def self.apply_le!(string)
    consume!(string.unpack(pattern_le))
  end
  
  # Get a class that would parse just the same, preserving only the fields passed in the array. This speeds
  # up parsing because we only extract and conform the fields that we need
  def self.only(*field_names)
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
  def self.filler
    only([])
  end
  
  # Only relevant for 1.9
  def self.byteify_string(string)
    string.force_encoding("ASCII-8BIT")
  end
    
  # Pack the instance of this struct
  def self.pack(instance, buffer = nil)
    
    # Preallocate a buffer just as big as me since we want everything to remain at fixed offsets
    buffer ||= (0xFF.chr * length)
    
    # We need to enforce ASCII-8bit encoding which in Ruby parlance is actually "bytestream"
    byteify_string(buffer) unless RUBY_VERSION < '1.9.0'
    
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
      
      # See above, byt we need to do this with the packed string as well
      byteify_string(packed) unless RUBY_VERSION < '1.9.0'
      
      buffer[offset...(offset+f.length)] = packed
    end
    raise "Resulting buffer not the same length, expected #{length} bytes but compued #{buffer.length}" if buffer.length != length
    buffer
  end
  
  private

  # extract_options! on a diet
  def self.count_and_opts_from(args)
    options, count = (args[-1].is_a?(Hash) ? DEF_OPTS.merge(args.pop) : DEF_OPTS), (args.shift || 1)
    [count, options]
  end
  
  public
  
  def []=(field, value)
    send("#{field}=", value)
  end
  
  def [](field)
    send(field)
  end
end
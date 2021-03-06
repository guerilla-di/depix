# coding: ASCII-8BIT

# Pay attention. The test verifies packing into bit blobs. These are much nahdier
# to compare and check as US-ASCII. Even though I am completely into Unicode this is exactly
# the moment to NOT use it.
require 'test/unit'
require File.dirname(__FILE__) + '/../lib/depix' unless defined?(Depix)

include Depix::Binary
include Depix::Binary::Fields

class BogusError < RuntimeError; end

class AlwaysInvalidField < Field
  def validate!(value)
    raise BogusError, "Never valid"
  end
  
  def pack(some_value)
    raise BogusError, "Will not pack"
  end
end

class AlwaysInvalidStruct
  def self.validate!(value)
    raise BogusError, "Never valid"
  end
  
  def self.pack(instance)
    raise BogusError, "Will not pack"
  end
end

module FieldConformity
  def conform_field!(f)
    assert_respond_to f, :name
    assert_respond_to f, :length
    assert_respond_to f, :pattern
    assert_respond_to f, :req
    assert_respond_to f, :req?
    assert_respond_to f, :rtype
    assert_respond_to f, :explain
    assert_respond_to f, :validate!
    assert_respond_to f, :pack
  end
  
  def assert_method_removed(f, method)
    fail("#{f.inspect} should not respond to #{method}") if f.respond_to?(method)
  end
end

class FieldExplainsItself < Test::Unit::TestCase
  def test_explain
    f = Field.new :rtype => self.class, :desc => "Eats people"
    assert_equal "(FieldExplainsItself) Eats people", f.explain
  end 
  
  def test_explain_with_verbatim
    f = Field.new :desc => "Eats people"
    assert_equal "Eats people", f.explain
  end

  def test_explain_with_verbatim_and_required
    f = Field.new :desc => "Eats people", :req => true
    assert_equal "Eats people - required", f.explain
  end

  def test_explain_with_no_data
    f = Field.new
    assert_equal "", f.explain
  end
  
  def test_explaion_for_empty_array
    f = ArrayField.new
    assert_equal "Empty array", f.explain
  end
  
  def test_explain_for_array_with_members
    f = ArrayField.new :members => [U8Field.new, U8Field.new], :desc => "Eats babies"
    assert_equal "(Array of 2 Integer fields) Eats babies", f.explain
  end

  def test_explain_for_nested_struct
    f = InnerField.new :cast => self.class, :desc => "Link to test case"
    assert_equal "(FieldExplainsItself) Link to test case", f.explain
  end

end

class TestField < Test::Unit::TestCase
  include FieldConformity
  
  def test_field_responds_to_all_meths
    f = Field.new
    conform_field!(f)
    
    assert_respond_to f, :name=
    assert_respond_to f, :length=
    assert_respond_to f, :pattern=
    assert_respond_to f, :req=
  end
  
  def test_field_supports_hash_initialization
    f = Field.new :name => "foo", :length => 3, :pattern => "C3"
    assert_equal ["foo", 3, "C3"], [f.name, f.length, f.pattern]
  end
  
  def test_req?
    f = Field.new :name => "foo"
    assert !f.req?

    f = Field.new :name => "foo", :req => false
    assert !f.req?

    f = Field.new :name => "foo", :req => true
    assert f.req?
  end
  
  def test_consume_for_field
    f = Field.new :name => "foo"
    
    assert_respond_to f, :consume!
    assert_nil f.consume!([])
    assert_equal 1, f.consume!([1])
    assert_equal 2, f.consume!([2,"foo"])

    ar = [1,2,3]
    f.consume!(ar)
    assert_equal [2,3], ar
  end 
  
  def test_validate
    f = Field.new
    f.rtype = self.class
    assert_nothing_raised { f.validate! nil }
    
    assert_raise(RuntimeError) { f.validate! "boo" }
    assert_nothing_raised { f.validate! self }
  end
  
  def test_validate_if_required
    f = Field.new
    f.req = true
    assert_raise(RuntimeError) { f.validate! nil }
  end
  
  def test_pack_raises
    f = Field.new
    assert_raise(RuntimeError) { f.pack("foo")}
  end
end

class TestArrayField < Test::Unit::TestCase
  include FieldConformity
  
  def test_array_field_conforms_to_field_and_has_extra_methods
    f = ArrayField.new
    conform_field!(f)
    
    assert_respond_to f, :name=
    
    assert_method_removed f, :length=
    assert_method_removed f, :pattern=
  end
  
  def test_array_does_not_allow_setting_length
    f = ArrayField.new
    assert_method_removed(f, :length=)
    assert_method_removed(f, :pattern=)
  end
  
  def test_array_field_has_members
    f = ArrayField.new
    assert_respond_to f, :members
    assert_respond_to f, :members=
  end
  
  def test_rtype_for_array_field_is_array
    casted = ArrayField.new(:members => [])
    assert_equal Array, casted.rtype
  end
  
  def test_array_field_accumulates_lengths_and_patterns_from_members
    f = ArrayField.new(:members => [
      Field.new(:name => :foo, :length => 1, :pattern => "C"),
      Field.new(:name => :bar, :length => 2, :pattern => "C2"),
    ])
    
    assert_equal 3, f.length
    assert_equal "CC2", f.pattern
  end
  
  def test_consume
    f = ArrayField.new :members => [Field.new, Field.new]
    assert_respond_to f, :consume!
    
    assert_equal [1,2], f.consume!([1,2])
  end
  
  def test_validate
    f = ArrayField.new :members => [Field.new(:rtype => self.class)]
    
    # Overflow
    assert_raise(RuntimeError) { f.validate!([nil, nil]) }
    
    # Just empty
    assert_nothing_raised { f.validate!([]) }
    
    # Nil vaue
    assert_nothing_raised { f.validate!([nil]) }

    # type cast
    assert_raise(RuntimeError) { f.validate!(["nil"]) }

    assert_nothing_raised { f.validate!([self]) }
  end
  
  def test_validate_fails_with_empty_array_and_required_field
    f = ArrayField.new :members => [Field.new(:rtype => self.class)], :req => true
    assert_raise(RuntimeError) { f.validate!([]) }
  end
  
  def test_validate_does_not_validate_inner_structure_if_no_value_present_and_field_is_not_required
    f = ArrayField.new :members => [AlwaysInvalidField.new]
    assert_nothing_raised { f.validate! [nil] }
  end
  
  
  def test_pack_tries_to_pack_inner_structures
    f = ArrayField.new :members => [AlwaysInvalidField.new]
    assert_raise(BogusError) { f.pack([1, 2]) }
  end
  
  def test_pack_pads_properly
    f = ArrayField.new :members => [U32Field.new, R32Field.new, R32Field.new]
    assert_equal "\x00\x00\x00\x1A?\x80\x00\x00@\x00\x00\x00", f.pack([26,1.0, 2.0])
    assert_equal f.length, f.pack([1.0, 2.0]).length
  end

  def test_does_not_try_to_pack_nil_values
    f = ArrayField.new(:members => [AlwaysInvalidField.new(:length => 2)])
    assert_equal 0xFF.chr * 2, f.pack([nil])
  end

end

class TestInnerField < Test::Unit::TestCase

  include FieldConformity
  
  def test_inner_field_conforms_to_field_and_has_extra_methods
    f = InnerField.new
    conform_field!(f)
        
    assert_respond_to f, :cast
    assert_respond_to f, :cast=
    
    assert_method_removed(f, :length=)
    assert_method_removed(f, :pattern=)
  end
  
  def test_inner_field_asks_cast_for_pattern_and_length
    sample = Struct.new(:length, :pattern).new
    sample.length, sample.pattern = 123, "C123"
    
    casted = InnerField.new(:cast => sample)
    assert_equal 123, casted.length
    assert_equal 'C123', casted.pattern
    
    assert_method_removed(casted, :length=)
    assert_method_removed(casted, :pattern=)
    
  end
  
  def test_rtype_for_inner_field_is_cast
    c = Class.new
    casted = InnerField.new(:cast => c)
    assert_equal c, casted.rtype
  end
  
  def test_consume
    catcher = Class.new do
      def self.consume!(arg)
        raise RuntimeError if arg == ["julik"]
      end
    end
    
    f = InnerField.new :cast => catcher
    assert_respond_to f, :consume!
    
    assert_raise(RuntimeError) { f.consume!(["julik"]) }
  end
  
  def test_validate_with_nil_and_no_requirement
    f = InnerField.new :cast => AlwaysInvalidStruct, :req => true
    assert_raise(RuntimeError) { f.validate!(nil) }
  end
  
  def test_validate
    f = InnerField.new :cast => AlwaysInvalidStruct
    assert_raise(BogusError) { f.validate!(AlwaysInvalidStruct.new) }
  end
  
  def test_pack_tries_to_pack_inner_structures
    f = InnerField.new :cast => AlwaysInvalidStruct
    assert_raise(BogusError) { f.pack(AlwaysInvalidStruct.new) }
  end
end

class TestWideIntField < Test::Unit::TestCase
  include FieldConformity
  
  def test_u32_field_contorms_to_basics
    f = U32Field.new :name  => :foo
    conform_field!(f)
    
    assert_equal "N", f.pattern
    assert_equal 4, f.length
    assert_equal :foo, f.name
    assert_equal 66, f.clean(66)
    assert_equal nil, f.clean(0xFFFFFFFF)
  end
  
  def test_validate
    f = U32Field.new
    
    assert_nothing_raised { f.validate! 8 }
    assert_nothing_raised { f.validate! 0 }
    assert_nothing_raised { f.validate!  65536 }
    assert_raise(RuntimeError) { f.validate!(0xFFFFFFFF) }
    assert_nothing_raised { f.validate!(0xFFFFFFFF - 1) }
    
  end
  
  def test_pack
    w = U32Field.new
    assert_equal "\000\000\000\036", w.pack(30)
    assert_equal "\xFF\xFF\xFF\xFF", w.pack(nil)
  end
end

class TestCharField < Test::Unit::TestCase
  include FieldConformity
  
  def test_char_field_conforms_to_basics
    f = CharField.new :name  => :foo
    conform_field!(f)
    assert_method_removed(f, :pattern=)
  end
  
  def test_char_field_pads
    f = CharField.new :name => :foo, :length => 15
    
    assert_equal "Z15", f.pattern
    assert_equal 15, f.length
    assert_equal String, f.rtype
  end
  
  def test_char_field_cleans_inner_nulls
    f = CharField.new :name => :foo, :length => 15
    assert_equal nil, f.clean("\0\0foo\0foo\0")
    assert_equal nil, f.clean("\0\0\0\377\377swoop\377\0bla\0\0\0\377\377\377\377\0\0\0")
  end
  
  def test_char_field_clean_blank
    f = CharField.new :name => :foo, :length => 15
    assert_equal nil, f.clean("\0")
    assert_equal nil, f.clean("\0\0\0\0\0\0")
    assert_equal nil, f.clean("\0\0\0\377\377\0\0\0")
    assert_equal nil, f.clean("\0\0foo\0foo\0")
  end
  
  def test_char_field_validates_overflow
    f = CharField.new :length => 2
    assert_raise(RuntimeError) { f.validate!("xxx")}
    assert_nothing_raised { f.validate!("xx")}
    assert_nothing_raised { f.validate!(nil)}
  end
  
  def test_char_field_validates_required_with_nil
    f = CharField.new :length => 2, :req => true
    assert_raise(RuntimeError) { f.validate!(nil)}
  end
  
  def test_char_field_packs
    f = CharField.new(:length => 6)
    assert_equal "xx\000\000\000\000", f.pack("xx")
    assert_equal "\xFF\xFF\xFF\xFF\xFF\xFF", f.pack("")
    assert_equal "\xFF\xFF\xFF\xFF\xFF\xFF", f.pack(nil)
  end
end

class TestFloatField < Test::Unit::TestCase
  include FieldConformity
  
  def test_r32_field_contorms_to_basics
    f = R32Field.new :name  => :foo
    conform_field!(f)
    
    assert_equal "g", f.pattern
    assert_equal 4, f.length
    assert_equal :foo, f.name
    assert_equal Float, f.rtype
  end
  
  def test_pack
    w = R32Field.new
    assert_equal "@fff", w.pack(3.6)
    blank = 0xFF.chr * 4
    assert_equal blank, w.pack(nil)
  end
end

class TestSmallintField < Test::Unit::TestCase
  include FieldConformity
  
  def test_smallint_conformity
    f = U8Field.new :name => :foo
    conform_field!(f)
    
    assert_method_removed(f, :pattern=)
    assert_method_removed(f, :length=)
  end
  
  def test_smallint_operation
    f = U8Field.new
    
    assert_equal 'c', f.pattern
    assert_equal 1, f.length
    assert_equal Integer, f.rtype
  end
  
  def test_smallint_clean
    f = U8Field.new
    assert_equal nil, f.clean(0xFF)
    assert_equal 10, f.clean(10)
  end
  
  def test_validate
    f = U8Field.new
    assert_nothing_raised { f.validate! 8 }
    assert_nothing_raised { f.validate! 0 }
    assert_raise(RuntimeError) { f.validate!( -1 ) }
    assert_raise(RuntimeError) { f.validate!( 255) }
    assert_raise(RuntimeError) { f.validate!( 256) }
  end
end

class TestDoubleField < Test::Unit::TestCase
  include FieldConformity
  
  def test_double_conformity
    f = U16Field.new :name => :foo
    conform_field!(f)

    assert_method_removed(f, :pattern=)
    assert_method_removed(f, :length=)
  end
  
  def test_double_operation
    f = U16Field.new
    
    assert_equal 'n', f.pattern
    assert_equal 2, f.length
    assert_equal Integer, f.rtype
  end
  
  def test_double_clean
    f = U16Field.new
    
    assert_equal nil, f.clean(0xFFFF)
    assert_equal 10, f.clean(10)
  end
  
  def test_validate
    f = U16Field.new
    assert_nothing_raised { f.validate! 8 }
    assert_nothing_raised { f.validate! 0 }
    assert_raise(RuntimeError) { f.validate!( -1) }
    assert_raise(RuntimeError) { f.validate!(  65535) }
    assert_raise(RuntimeError) { f.validate!(  65536) }
  end
end

class TestFillerField < Test::Unit::TestCase
  include FieldConformity
  
  def test_field_conformity
    f = Filler.new
    conform_field!(f)
    assert_equal "x1", f.pattern
  end
  
  def test_filler_does_not_allow_setting_pattern
    assert_method_removed(Filler.new, :pattern=)
  end
  
  def test_pattern_discards_value
    data = [1,2,3].pack("ccc")
    filler = Filler.new(:length => 3)
    unpacked = data.unpack(filler.pattern)
    assert_equal [], unpacked
  end

  def test_consume_does_not_touch_stack
    data = [1,2,3]
    data.freeze
    assert_nothing_raised { Filler.new(:length => 1).consume(data) }
  end
  
  def test_pack_raises
    assert_raise(RuntimeError) { Filler.new(:length => 3).pack('xxx') }
  end
end

class TestFieldEmit < Test::Unit::TestCase
  include FieldConformity
  
  def test_emit_short
    f = U8Field.new
    conform_field!(f)
    
    f = U8Field.new(:desc => "Dick length")
    conform_field!(f)
    assert_equal "c", f.pattern
    assert_equal 1, f.length
  end

  def test_emit_double
    f = U16Field.new
    conform_field!(f)
    
    f = U16Field.new(:desc => "Dick length")
    conform_field!(f)
    assert_equal "n", f.pattern
    assert_equal 2, f.length
  end

  def test_emit_char
    f = CharField.new
    conform_field!(f)
    
    assert_equal "Z1", f.pattern
    assert_equal 1, f.length
    
    f = CharField.new :length => 3
    conform_field!(f)
    
    assert_equal "Z3", f.pattern
    assert_equal 3, f.length
  end
  
  def test_emit_float
    f = R32Field.new
    conform_field!(f)
    
    assert_equal "g", f.pattern
    assert_equal 4, f.length
  end
end

class TestStructure < Test::Unit::TestCase
  
  def test_dict_has_a_fields_array
    dict_class = Class.new(Structure)
    assert_respond_to dict_class, :fields
    assert_equal [], dict_class.fields
  end
  
  def test_dict_responds_to_validate
    dict_class = Class.new(Structure)
    assert_respond_to dict_class, :validate!
    one = dict_class.new
  end
  
  def test_dict_fields_array_not_class_shared
    d1, d2 = (0..1).map{|_| Class.new(Structure) }
    
    d1.fields << 1
    d2.fields << 2
    assert_not_equal d1.fields, d2.fields
  end
  
  def test_dict_responds_to_emit_methods_from_fields
    c = Class.new(Structure)

    emitter_methods = Field.methods.grep(/^emit_/)
    emitter_methods.each do | m |
      assert_respond_to c, m.gsub(/^emit_/, '')
    end
  end
  
  def test_empty_dict_has_empty_template
    c = Class.new(Structure)
    assert_respond_to c, :pattern
    assert_equal '', c.pattern
    assert_equal 0, c.length
  end

  def test_dict_assembles_template
    c = Class.new(Structure)
    c.fields << CharField.new
    c.fields << CharField.new
    
    assert_respond_to c, :pattern
    assert_equal 'Z1Z1', c.pattern
    assert_equal 2, c.length
  end

  def test_dict_does_not_validate_inner_nil
    wrapper_class = Class.new(Structure) do 
      u32 :bigint
      inner :invalid, AlwaysInvalidStruct
    end
    struct = wrapper_class.new
    assert_nothing_raised { wrapper_class.validate!(struct) }
  end
  
  def test_dict_calls_validate
    wrapper_class = Class.new(Structure) do 
      u32 :bigint
      inner :invalid, AlwaysInvalidStruct, :req => true
    end
    
    struct = wrapper_class.new
    struct.invalid = AlwaysInvalidStruct.new
    
    assert_raise(BogusError) { wrapper_class.validate!(struct) }
  end
end

class TestStructureConsume < Test::Unit::TestCase
  def test_dict_consume
    c = Class.new(Structure)
    c.char :foo
    c.char :bar
    
    result = c.consume!(["a", "b"])
    assert_kind_of c, result
    
    assert_equal "a", result.foo
    assert_equal "b", result.bar
    assert_equal "a", result[:foo]
    assert_equal "a", result["foo"]
  end
  
end

class TestStructureEmitDSL < Test::Unit::TestCase
  
  def test_dict_emit_char_of_48_bytes
    c = Class.new(Structure)
    c.blanking :reserved, :length => 48, :desc => "Reserved"
    assert c.instance_methods.map{|e| e.to_s }.include?("reserved"),
      "Should create the tag accessor"
    
    assert_equal 1, c.fields.length
    field = c.fields[0]
    
    assert_equal 48, field.length
    assert_equal "Z48", field.pattern
    assert_equal :reserved, field.name
  end
  
  
  def test_dict_emit_char_of_one_byte
    c = Class.new(Structure)
    c.char :tag, :desc => "Some name"
    assert c.instance_methods.map{|e| e.to_s }.include?("tag"),
      "Should create the tag accessor"
    
    assert_equal 1, c.fields.length
    field = c.fields[0]

    assert_equal 1, field.length
    assert_equal "Z1", field.pattern
    assert_equal :tag, field.name
  end
  
  def test_dict_emit_char_with_length
    c = Class.new(Structure)
    c.char :joe, 3, :desc => "Some name"

    assert c.instance_methods.map{|e| e.to_s }.include?("joe")
    
    assert_equal 1, c.fields.length
    field = c.fields[0]
    assert_equal 3, field.length
    assert_equal "Z3", field.pattern
    assert_equal :joe, field.name
  end
  
  def test_dict_emit_u32
    c = Class.new(Structure)
    c.u32 :num, :desc => "Huge number"

    assert c.instance_methods.map{|e| e.to_s }.include?("num")
    
    assert_equal 1, c.fields.length
    field = c.fields[0]
    assert_equal 4, field.length
    assert_equal "N", field.pattern
    assert_equal :num, field.name
  end
  
  def test_dict_emit_r32
    c = Class.new(Structure)
    c.r32 :joe, :req => true

    assert c.instance_methods.map{|e| e.to_s }.include?("joe")
    
    assert_equal 1, c.fields.length
    field = c.fields[0]
    assert_equal 4, field.length
    assert_equal "g", field.pattern
    assert_equal true, field.req?
  end
  
  def test_dict_emit_u8
    c = Class.new(Structure)
    c.u8 :joe, :req => true

    assert c.instance_methods.map{|e| e.to_s }.include?("joe")
    
    assert_equal 1, c.fields.length

    field = c.fields[0]
    assert_equal 1, field.length
    assert_equal "c", field.pattern
    assert_equal true, field.req?
  end
  
  def test_dict_emit_u16
    c = Class.new(Structure)
    c.u16 :joe, :req => true, :desc => "A little bit of numbers"
    
    assert c.instance_methods.map{|e| e.to_s }.include?("joe")
    
    assert_equal 1, c.fields.length

    field = c.fields[0]
    
    assert_equal 2, field.length
    assert_equal "n", field.pattern
    assert_equal "A little bit of numbers", field.desc
  end
  
  def test_dict_emit_array
    c = Class.new(Structure)
    c.array :point, :u32, :desc => "Two coordinates"
    
    assert c.instance_methods.map{|e| e.to_s }.include?("point")

    assert_equal 1, c.fields.length
    field = c.fields[0]
    
    assert_kind_of ArrayField, field
    assert_equal "Two coordinates", field.desc
    assert_equal 1, field.members.length
    assert_equal U32Field, field.members[0].class
  end
  
  def test_dict_emit_inner
    c = Class.new(Structure)
    c2 = Class.new(Structure)
    
    c.inner :nest, c2, :desc => "Nested struct"
    
    assert c.instance_methods.map{|e| e.to_s }.include?("nest")
    
    assert_equal 1, c.fields.length
    f = c.fields[0]
    
    assert_kind_of InnerField, f
    assert_equal "Nested struct", f.desc
    assert_equal c2, f.cast
  end
  
  def test_dict_emit_array_of_substructs
    c = Class.new(Structure)
    c2 = Class.new(Structure)
    
    c2.u32 :some_num
    c.array :inners, c2, 8, :desc => "Inner items"
    
    assert c.instance_methods.map{|e| e.to_s }.include?("inners")
    
    assert_equal 1, c.fields.length
    f = c.fields[0]
    
    assert_kind_of ArrayField, f
    assert_equal "Inner items", f.desc
    
    assert_equal 8, f.members.length, "8 inner members should be there"
    
    mem = f.members[0]
    assert_equal c2, mem.cast
  end
end

class TestStructureCompact < Test::Unit::TestCase
  def test_only_with_interspersed_fields
    c = Class.new(Structure) do
      u8 :some
      u8 :another
      u8 :third
    end
    
    distill = c.only(:another)

    assert_equal distill.length, c.length, "The distilled struct should occupy the same space"

    assert distill.ancestors.include?(c)
    assert_equal 3, distill.fields.length
    
    assert_kind_of Filler, distill.fields[0]
    assert_equal 1, distill.fields[0].length
    
    assert_kind_of U8Field, distill.fields[1]
    assert_equal 1, distill.fields[0].length

    assert_kind_of Filler, distill.fields[2]
    assert_equal 1, distill.fields[2].length
    
  end
  
  def test_only_with_fields_in_a_row
    c = Class.new(Structure) do
      u8   :some
      u32  :another
      u8   :third
      u32  :fourth
      char :fifth, 10
    end
    
    distill = c.only(:third)
    assert_equal distill.length, c.length, "The distilled struct should occupy the same space"
    assert_equal 3, distill.fields.length
    
    result = distill.apply!("abcdefhjhjkujkdkklsalierioeiore")
    
    assert_kind_of Filler, distill.fields[0]
    assert_equal 5, distill.fields[0].length

    assert_kind_of Filler, distill.fields[2]
    assert_equal 14, distill.fields[2].length
    
    assert_nil result.some
    assert_nil result.fourth
  end
  
  def test_get_filler
    c = Class.new(Structure) do
      u32 :some
    end
    
    filler = c.filler
    assert_equal filler.length, c.length
    assert_equal 1, c.fields.length
  end
  
  def test_filler_parses_the_same
    c = Class.new(Structure) do
      u8 :first
      u8 :second
      u8 :third
    end
    
    distill = c.only(:second)
    
    data = [1,2,3].pack("ccc")
    
    base_r = c.apply!(data)
    assert_not_nil  base_r.first
    assert_not_nil  base_r.third
    assert_equal 2, base_r.second
    
    r = distill.apply!(data)
    assert_nil r.first
    assert_nil r.third
    assert_equal 2, r.second
  end
end

class TestStructureApply < Test::Unit::TestCase
  def test_apply
    struct = Class.new(Structure) do
      char :name, "julik".length
      char :module, "depix".length
    end
    
    result = struct.apply!("julikdepix")
    assert_equal "julik", result.name
    assert_equal "depix", result.module
  end
end
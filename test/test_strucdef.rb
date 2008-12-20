require File.dirname(__FILE__) + '/../lib/depix'
require File.dirname(__FILE__) + '/../lib/depix/structdef'
require 'test/unit'

include Depix

module FieldConformity
  def conform_field!(f)
    assert_respond_to f, :name
    assert_respond_to f, :length
    assert_respond_to f, :pattern
    assert_respond_to f, :req
    assert_respond_to f, :req?
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
end

class TestArrayField < Test::Unit::TestCase
  include FieldConformity
  
  def test_array_field_conform_field!s_to_field_and_has_extra_methods
    f = ArrayField.new
    conform_field!(f)
    
    assert_respond_to f, :name=

    assert_raise(NoMethodError) { f.length = 1 }
    assert_raise(NoMethodError) { f.pattern = 'C' }
  end
  
  def test_array_field_has_members
    f = ArrayField.new
    assert_respond_to f, :members
    assert_respond_to f, :members=
  end
  
  def test_array_field_accumulates_lengths_and_patterns_from_members
    f = ArrayField.new(:members => [
      Field.new(:name => :foo, :length => 1, :pattern => "C"),
      Field.new(:name => :bar, :length => 2, :pattern => "C2"),
    ])
    
    assert_equal 3, f.length
    assert_equal "CC2", f.pattern
  end
end

class TestInnerField < Test::Unit::TestCase
  include FieldConformity
  
  def test_inner_field_conform_field!s_to_field_and_has_extra_methods
    f = InnerField.new
    conform_field!(f)
        
    assert_respond_to f, :cast
    assert_respond_to f, :cast=
    
    assert_raise(NoMethodError) { f.length = 1 }
    assert_raise(NoMethodError) { f.pattern = 'C' }
  end
  
  def test_inner_field_asks_cast_for_pattern_and_length
    sample = Struct.new(:length, :pattern).new
    sample.length, sample.pattern = 123, "C123"
    
    casted = InnerField.new(:cast => sample)
    assert_equal 123, casted.length
    assert_equal 'C123', casted.pattern
  end
end

class TestFieldEmit < Test::Unit::TestCase
  include FieldConformity
  
  def test_emit_short
    f = Field.emit_u8
    conform_field!(f)
    
    f = Field.emit_u8(:desc => "Dick length")
    conform_field!(f)
    assert_equal "c", f.pattern
    assert_equal 1, f.length
  end

  def test_emit_double
    f = Field.emit_u16
    conform_field!(f)
    
    f = Field.emit_u16(:desc => "Dick length")
    conform_field!(f)
    assert_equal "n", f.pattern
    assert_equal 2, f.length
  end

  def test_emit_char
    f = Field.emit_char
    conform_field!(f)
    
    assert_equal "C1", f.pattern
    assert_equal 1, f.length

    f = Field.emit_char :length => 3
    conform_field!(f)
    
    assert_equal "C3", f.pattern
    assert_equal 3, f.length
  end
  
  def test_emit_float
    f = Field.emit_r32
    conform_field!(f)
    
    assert_equal "g", f.pattern
    assert_equal 4, f.length
  end
end

class TestDict < Test::Unit::TestCase
  
  def test_dict_has_a_fields_array
    dict_class = Class.new(Dict)
    assert_respond_to dict_class, :fields
    assert_equal [], dict_class.fields
  end
  
  def test_dict_fields_array_not_class_shared
    d1, d2 = (0..1).map{|_| Class.new(Dict) }
    
    d1.fields << 1
    d2.fields << 2
    assert_not_equal d1.fields, d2.fields
  end
  
  def test_dict_responds_to_emit_methods_from_fields
    c = Class.new(Dict)

    emitter_methods = Field.methods.grep(/^emit_/)
    emitter_methods.each do | m |
      assert_respond_to c, m.gsub(/^emit_/, '')
    end
  end
  
end


class TestDictEmitDSL < Test::Unit::TestCase

  def test_dict_emit_char
    c = Class.new(Dict)
    c.char :tag, :desc => "Some name"
    
    assert c.instance_methods.include?("tag")
    
    assert_equal 1, c.fields.length
    field = c.fields[0]
    assert_equal 1, field.length
    assert_equal "C1", field.pattern
    assert_equal :tag, field.name
  end
  
  def test_dict_emit_char_with_length
    c = Class.new(Dict)
    c.char :joe, 3, :desc => "Some name"

    assert c.instance_methods.include?("joe")
    
    assert_equal 1, c.fields.length
    field = c.fields[0]
    assert_equal 3, field.length
    assert_equal "C3", field.pattern
    assert_equal :joe, field.name
  end
  
  def test_dict_emit_u32
    c = Class.new(Dict)
    c.u32 :num, :desc => "Huge number"

    assert c.instance_methods.include?("num")
    
    assert_equal 1, c.fields.length
    field = c.fields[0]
    assert_equal 4, field.length
    assert_equal "N", field.pattern
    assert_equal :num, field.name
  end
  
  def test_dict_emit_r32
    c = Class.new(Dict)
    c.r32 :joe, :req => true

    assert c.instance_methods.include?("joe")
    
    assert_equal 1, c.fields.length
    field = c.fields[0]
    assert_equal 4, field.length
    assert_equal "g", field.pattern
    assert_equal true, field.req?
  end
  
  def test_dict_emit_u8
    c = Class.new(Dict)
    c.u8 :joe, :req => true

    assert c.instance_methods.include?("joe")
    
    assert_equal 1, c.fields.length

    field = c.fields[0]
    assert_equal 1, field.length
    assert_equal "c", field.pattern
    assert_equal true, field.req?
  end
  
  def test_dict_emit_u16
    c = Class.new(Dict)
    c.u16 :joe, :req => true, :desc => "A little bit of numbers"
    
    assert c.instance_methods.include?("joe")
    
    assert_equal 1, c.fields.length

    field = c.fields[0]
    
    assert_equal 2, field.length
    assert_equal "n", field.pattern
    assert_equal "A little bit of numbers", field.desc
  end
  
  def test_dict_emit_array
    c = Class.new(Dict)
    c.array :point, :u32, :desc => "Two coordinates"
    
    assert c.instance_methods.include?("point")

    assert_equal 1, c.fields.length
    field = c.fields[0]
    
    assert_kind_of ArrayField, field
    assert_equal "Two coordinates", field.desc
    assert_equal 1, field.members.length
    assert_equal Field, field.members[0].class 
  end
  
  def test_dict_emit_inner
    c = Class.new(Dict)
    c2 = Class.new(Dict)
    
    c.inner :nest, c2, :desc => "Nested struct"
    
    assert c.instance_methods.include?("nest")
    
    assert_equal 1, c.fields.length
    f = c.fields[0]
    
    assert_kind_of InnerField, f
    assert_equal "Nested struct", f.desc
    assert_equal c2, f.cast
  end
  
  def test_dict_emit_array_of_substructs
    c = Class.new(Dict)
    c2 = Class.new(Dict)
    
    c2.u32 :some_num
    c.array :inners, c2, 8, :desc => "Inner items"
    
    assert c.instance_methods.include?("inners")
    
    assert_equal 1, c.fields.length
    f = c.fields[0]
    
    assert_kind_of ArrayField, f
    assert_equal "Inner items", f.desc
    
    assert_equal 8, f.members.length, "8 inner members should be there"
    
    mem = f.members[0]
    assert_equal c2, mem.cast
  end
end
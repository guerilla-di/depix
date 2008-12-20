require File.dirname(__FILE__) + '/../lib/depix'
require File.dirname(__FILE__) + '/../lib/depix/new_structs'
require 'test/unit'

include Depix

module FieldConformity
  def conform_field!(f)
    assert_respond_to f, :name
    assert_respond_to f, :length
    assert_respond_to f, :pattern
    assert_respond_to f, :required
    assert_respond_to f, :required?
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
    assert_respond_to f, :required=
  end
  
  def test_field_supports_hash_initialization
    f = Field.new :name => "foo", :length => 3, :pattern => "C3"
    assert_equal ["foo", 3, "C3"], [f.name, f.length, f.pattern]
  end
  
  def test_required?
    f = Field.new :name => "foo"
    assert !f.required?

    f = Field.new :name => "foo", :required => false
    assert !f.required?

    f = Field.new :name => "foo", :required => true
    assert f.required?
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
  
end
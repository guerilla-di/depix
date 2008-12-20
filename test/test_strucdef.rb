require File.dirname(__FILE__) + '/../lib/depix'
require File.dirname(__FILE__) + '/../lib/depix/new_structs'
require 'test/unit'

class TestDepix_Structdef < Test::Unit::TestCase
  def test_cdefined
    assert_nothing_raised { Depix::Structdef }
  end
  
  def test_succeeds_for_a_single_uint
    cls = Class.new(Depix::Structdef) do
      u32 :v
    end

    assert_equal 'N1', cls.to_template
    assert_equal 4, cls.byte_length
    assert_equal ['v'], cls.fields
    assert_equal ['v'], cls.keys
  end
  
  def test_succeeds_for_a_char
    cls = Class.new(Depix::Structdef) do
      char :v, 23
    end
    assert_equal 'C23', cls.to_template
    assert_equal 23, cls.byte_length
    assert_equal ['v'], cls.fields
    assert_equal ['v'], cls.keys
  end
  
  def test_succeeds_for_two_types
    cls = Class.new(Depix::Structdef) do
      char :v, 23
      u32 :another
    end
    assert_equal 'C23N1', cls.to_template
    assert_equal 27, cls.byte_length
    assert_equal ['v', 'another'], cls.fields
    assert_equal ['v', 'another'], cls.keys
  end
  
  def test_succeeds_for_array_of_two_uints
    cls = Class.new(Depix::Structdef) do
      array :values, :u32, 2
    end
    assert_equal 'N1N1', cls.to_template
    assert_equal 8, cls.byte_length
    assert_equal ['values'], cls.fields
    assert_equal ['values.0', 'values.1'], cls.keys
  end
  
  def test_describe
    cls = Class.new(Depix::Structdef) do
      u32 :some, :desc => 'Futuristic'
    end
  end

end
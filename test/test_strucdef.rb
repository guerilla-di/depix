require File.dirname(__FILE__) + '/../lib/depix'
require 'test/unit'

class StructdefTest < Test::Unit::TestCase
  def test_cdefined
    assert_nothing_raised { Depix::Strucdef }
  end
  
  def test_strucdef_succeeds
    
  end
end
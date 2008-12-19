require File.dirname(__FILE__) + '/../lib/depix'
require 'test/unit'

class StructsTest < Test::Unit::TestCase
  def test_struct_size
    int = [[:some, Integer, 13]]
    assert_equal 13, Depix::Structs.struct_size(int)

    two_ints = [[:some, String, 13], [:some, String, 13]]
    assert_equal 26, Depix::Structs.struct_size(two_ints)
    
    nested_struct = [[:some, String, 10], [:some, two_ints, Depix::Structs.struct_size(two_ints)]]
    assert_equal 36, Depix::Structs.struct_size(nested_struct)
  end
  
  def test_integer_template
    assert_equal "N", Depix::Structs.integer_template(4, true)
    assert_equal "V", Depix::Structs.integer_template(4, false)

    assert_equal "n", Depix::Structs.integer_template(2, true)
    assert_equal "v", Depix::Structs.integer_template(2, false)
  end
  
  def test_struct_to_template
    one_int = [[:some, Integer, 4]]
    assert_equal [["some"], "N"], Depix::Structs.struct_to_template(one_int, true)
    assert_equal [["some"], "V"], Depix::Structs.struct_to_template(one_int, false)

    float = [[:afloat, Float, 4]]
    assert_equal [["afloat"], "g"], Depix::Structs.struct_to_template(float, true)
    assert_equal [["afloat"], "f"], Depix::Structs.struct_to_template(float, false)

    two_ints = [[:some, Integer, 4], [:another, Integer, 4]]
    assert_equal [["some", "another"], "NN"], Depix::Structs.struct_to_template(two_ints, true)
    assert_equal [["some", "another"], "VV"], Depix::Structs.struct_to_template(two_ints, false)

    two_ints = [[:some, Integer, 4], [:another, Integer, 2]]
    assert_equal [["some", "another"], "Nn"], Depix::Structs.struct_to_template(two_ints, true)

    two_ints = [[:some, Integer, 4], [:another, Integer, 2], [:str, String, 5]]
    assert_equal [["some", "another", "str"], "NnA5"], Depix::Structs.struct_to_template(two_ints, true)
    
    int_and_nest = [
      [:some, Integer, 4],
      [:another, [[:inner, String, 3]], 3]
    ]
    assert_equal [["some", "another.inner"], "NA3"], Depix::Structs.struct_to_template(int_and_nest, true)
  end
  
  def test_template_length
    assert_equal 2084, Depix::Structs::TEMPLATE_LENGTH
  end
  
  def test_dpx_info_present
    assert_nothing_raised { Depix::Structs.const_get(:DPX_INFO) }
  end
end

class ReaderTest < Test::Unit::TestCase
  def test_nestify
    k, v = ["foo", "bar"], [1, 2]
    assert_equal( {"foo"=>1, "bar"=> 2}, Depix::Reader.nestify(k,v))

    k, v = ["foo", "bar.baz"], [1, 2]
    assert_equal( {"foo"=>1, "bar"=> {"baz"=> 2}}, Depix::Reader.nestify(k,v))

    k, v = ["foo", "bar.baz", "bar.bam"], [1, 2, 3]
    assert_equal( {"foo"=>1, "bar"=> {"baz"=> 2, "bam" => 3}}, Depix::Reader.nestify(k,v))

    k, v = ["foo", "bar.baz.boo", "bar.baz.doo"], [1, 2, 3]
    assert_equal( {"foo"=>1, "bar"=> {"baz"=> {"boo" => 2, "doo" => 3}}}, Depix::Reader.nestify(k,v))

    k, v = ["foo", "bar.0", "bar.1"], [1, 2, 3]
    assert_equal( {"foo"=>1, "bar"=>{0=>2, 1=>3}}, Depix::Reader.nestify(k,v))

    k, v = ["foo", "bar.0.baz", "bar.0.dam"], [1, 2, 3]
    assert_equal( {"foo"=>1, "bar"=>{0=>{"dam"=>3, "baz"=>2}}}, Depix::Reader.nestify(k,v))
  end
  
  def test_parse
    file = 'samples/E012_P001_L000002_lin.0001.dpx'
    parsed = Depix::Reader.from_file(file)
    assert_equal 'SDPX', parsed.file.magic
    assert_equal 320, image.pixels_per_line
    assert_equal 240, image.lines_per_element
  end
end
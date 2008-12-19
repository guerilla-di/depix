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

class EichTest < Test::Unit::TestCase
  def test_eich
    eich = Depix::H.new
    assert_nothing_raised { assert_not_nil eich.foo = 1 }
    assert_nothing_raised { eich.foo }
    assert_equal ['foo'], eich.keys
    assert_equal 1, eich.foo
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
  
  def test_parsed_properly
    file = 'samples/E012_P001_L000002_lin.0001.dpx'
    parsed = Depix::Reader.from_file(file)
    assert_equal "SDPX", parsed.file.magic
    assert_equal 8192, parsed.file.image_offset
    assert_equal "V1.0", parsed.file.version
    assert_equal 319488, parsed.file.file_size
    assert_equal 1, parsed.file.ditto_key
    assert_equal 1664, parsed.file.generic_size
    assert_equal 384, parsed.file.industry_size
    assert_equal 6144, parsed.file.user_size
    assert_equal "E012_P001_L000002_lin.0001.dpx", parsed.file.filename
    assert_equal "2008:12:19:01:18:37:CEST", parsed.file.timestamp
    assert_equal "UTODESK", parsed.file.creator
    assert_equal 0, parsed.image.orientation
    assert_equal 1, parsed.image.number_elements
    assert_equal 320, parsed.image.pixels_per_line
    assert_equal 240, parsed.image.lines_per_element
    assert_equal 0, parsed.image.image_elements[0].data_sign
    assert_equal 0, parsed.image.image_elements[0].low_data
    assert_equal 0.0, parsed.image.image_elements[0].low_quantity
    assert_equal 1023, parsed.image.image_elements[0].high_data
    assert_in_delta 2.04699993133545, parsed.image.image_elements[0].high_quantity, 1.0 ** -10
    
    assert_equal 50, parsed.image.image_elements[0].descriptor # RGB :-)
    assert_equal 2, parsed.image.image_elements[0].transfer
    assert_equal 2, parsed.image.image_elements[0].colorimetric
    assert_equal 10, parsed.image.image_elements[0].bit_size
    assert_equal 1, parsed.image.image_elements[0].packing
    assert_equal 0, parsed.image.image_elements[0].encoding
    assert_equal 8192, parsed.image.image_elements[0].data_offset
    assert_equal 0, parsed.image.image_elements[0].end_of_line_padding
    assert_equal 0, parsed.image.image_elements[0].end_of_image_padding
    assert_equal "IMAGE DESCRIPTION DATA        P", parsed.image.image_elements[0].description
  #  assert_equal "E012x�", parsed.orientation.device
    assert_equal 853, parsed.orientation.aspect_ratio[0]
    assert_equal 640, parsed.orientation.aspect_ratio[1]

    assert_equal '75', parsed.film.id
    assert_equal '00', parsed.film.type
    assert_equal '19', parsed.film.offset
    assert_equal '740612', parsed.film.prefix
    assert_equal '9841', parsed.film.count
    assert_equal 1, parsed.film.frame_position
    assert_equal 2, parsed.film.sequence_extent
    assert_equal 1, parsed.film.held_count
    assert_equal 25.0, parsed.film.frame_rate
    assert_equal 18157848, parsed.television.time_code
    assert_equal 0, parsed.television.user_bits
  end
  
  def test_syntethics
    assert_nothing_raised { Depix::Synthetics }

    file = 'samples/E012_P001_L000002_lin.0001.dpx'
    parsed = Depix::Reader.from_file(file)
    assert_equal "E012", parsed.flame_reel
    assert_equal "75 00 19 740612 9841", parsed.keycode
  end
end
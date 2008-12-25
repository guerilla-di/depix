require File.dirname(__FILE__) + '/../lib/depix'
require 'test/unit'

class ReaderTest < Test::Unit::TestCase
  
  SAMPLE_DPX = File.dirname(__FILE__) + '/samples/E012_P001_L000002_lin.0001.dpx'
    
  def test_parsed_properly
    file = SAMPLE_DPX
    parsed = Depix.from_file(file)
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
    assert_equal "IMAGE DESCRIPTION DATA        \000P", parsed.image.image_elements[0].description
    assert_equal "E012\000\000\000\000x\340\264\020\000\000\000\000\005", 
      parsed.orientation.device #- this is where Flame writes the reel
    
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

    file = SAMPLE_DPX
    parsed = Depix.from_file(file)
    assert_equal false, parsed.le?
    assert_equal "75 00 19 740612 9841", parsed.keycode
    assert_equal "01:15:11:18", parsed.time_code.to_s
    assert_equal :RGB, parsed.component_type
    assert_equal :Linear, parsed.colorimetric
    assert_equal "E012", parsed.flame_reel
    assert_equal "1.33", parsed.aspect
  end
  
  def test_parsed_properly_using_compact_structs
    file = SAMPLE_DPX
    assert_nothing_raised { Depix.from_file(file, compact = true) }
  end
  
  def test_describe
    assert_nothing_raised do
      desc =  Depix.describe_file(SAMPLE_DPX)
      assert_match(/320/, desc)
      assert_match(/Offset to data for this image element/, desc)
    end
  end
  
  def test_parsing_something_else_should_raise
    s = "Mary had a little lamb"
    assert_raise(Depix::InvalidHeader) { Depix.from_string(s) }
    
    s = "Mary had a little lamb" * 1000
    assert_raise(Depix::InvalidHeader) { Depix.from_string(s) }

    s = "SDPX Mary had a little lamb" * 1000
    assert_raise(Depix::InvalidHeader) { Depix.from_string(s) }

  end
end
require File.dirname(__FILE__) + '/../lib/depix'
require 'test/unit'
require "fileutils"

SAMPLE_DPX = File.dirname(__FILE__) + '/samples/E012_P001_L000002_lin.0001.dpx'

class ReaderTest < Test::Unit::TestCase
  
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
    assert_equal nil, parsed.file.creator
    assert_equal 0, parsed.image.orientation
    
    assert_equal 320, parsed.image.pixels_per_line
    assert_equal 240, parsed.image.lines_per_element

    assert_equal 1, parsed.image.number_elements
    assert_equal 1, parsed.image.image_elements.length
    ie = parsed.image.image_elements[0]
    
    assert_equal 0, ie.data_sign
    assert_equal 0, ie.low_data
    assert_equal 0.0, ie.low_quantity
    assert_equal 1023, ie.high_data
    assert_in_delta 2.04699993133545, ie.high_quantity, 1.0 ** -10
    
    assert_equal 50,    ie.descriptor # RGB :-)
    assert_equal 2,     ie.transfer
    assert_equal 2,     ie.colorimetric
    assert_equal 10,    ie.bit_size
    assert_equal 1,     ie.packing
    assert_equal 0,     ie.encoding
    assert_equal 8192,  ie.data_offset
    assert_equal 0,     ie.end_of_line_padding
    assert_equal 0,     ie.end_of_image_padding
    assert_equal "IMAGE DESCRIPTION DATA        ", ie.description
    assert_equal "E012", 
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
  
  def test_packing
    original_header = File.read(SAMPLE_DPX)[0...Depix::DPX.length]
    
    assert_nothing_raised do
      dpx = Depix.from_string(original_header)
      packed =  Depix::DPX.pack(dpx, original_header.dup)
    
      dpx2 = Depix.from_string(packed)
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
  
  def test_parsing_gluetools_file
    # This file comes from GlueTools
    dpx = Depix.from_file(File.dirname(__FILE__) + "/samples/gluetools_file_header.dpx")
    assert_equal "03:09:00:17", dpx.time_code.to_s
  end
  
  def test_parse_with_timecode_mismatch
    # This file has mismatching framerates in the film and television headers 
    dpx = Depix.from_file(File.dirname(__FILE__) + "/samples/northlight_tc_mode_mismatch.dpx")
    assert_equal "22:02:18:24", dpx.time_code.to_s
  end

  def test_parse_zero_tc_fps
    # This file has mismatching framerates in the film and television headers 
    dpx = Depix.from_file(File.dirname(__FILE__) + "/samples/from_nuke_no_TC_meta.dpx")
    assert_equal "05:00:59:20", dpx.time_code.to_s
    assert_equal 25, dpx.time_code.fps
  end

end

class EditorTest < Test::Unit::TestCase
  def test_instantiation
    e = Depix::Editor.new(SAMPLE_DPX)
    assert_not_nil e
    assert_equal SAMPLE_DPX, e.path
    assert_respond_to e, :flame_reel
    assert_equal "E012", e.flame_reel
  end
  
  def test_copy_from
    e = Depix::Editor.new(SAMPLE_DPX)
    assert_equal SAMPLE_DPX, e.path
    another = Depix.from_file(File.dirname(__FILE__) + "/samples/northlight_tc_mode_mismatch.dpx")
    e.copy_from(another)
    assert_equal "Northlight", e.orientation.device
  end
  
  def test_commit
    temp_path = SAMPLE_DPX + ".test"
    FileUtils.cp(SAMPLE_DPX, temp_path)
    begin
      e  = Depix::Editor.new(temp_path)
      e.flame_reel = "E013"

      assert_nothing_raised { e.commit! }

      re_read = Depix.from_file(temp_path)
      assert_equal "E013", re_read.orientation.device
    ensure
      File.unlink(temp_path)
    end
  end
end
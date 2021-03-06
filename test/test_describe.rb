require 'test/unit'
require File.dirname(__FILE__) + '/../lib/depix' unless defined?(Depix)
require "cli_test"

class TestDescribe < Test::Unit::TestCase
  BIN_P = File.dirname(__FILE__) + "/../bin/depix_describe"
  OBSOLETE_BINARY = File.dirname(__FILE__) + "/../bin/depix-describe"
  SAMPLE_DPX = File.dirname(__FILE__) + '/samples/E012_P001_L000002_lin.0001.dpx'
  
  def test_app
    s, o, e = CLITest.new(BIN_P).run( File.dirname(__FILE__) + "/samples/gluetools_file_header.dpx")
    assert s.zero?, "Should exit without error"
    assert o.include?("03:09:00:17"), "Should include the timecode"
  end
  
  def test_obsolete_binary
    s, o, e = CLITest.new(OBSOLETE_BINARY).run(File.dirname(__FILE__) + "/samples/gluetools_file_header.dpx")
    assert !s.zero?
    assert_match /is now called/, e
  end
  
  def test_describe_class_simple
    desc =  Depix::Describe.new.describe(SAMPLE_DPX)
    assert_match(/320/, desc)
    assert_match(/Offset to data for this image element/, desc)
  end
  
  def test_describe_synthetics
    desc =  Depix::Describe.new.describe_synthetics(SAMPLE_DPX, false)
    assert desc.include?("01:15:11:18")
  end
  
end
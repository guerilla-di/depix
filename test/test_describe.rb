require 'test/unit'
require File.dirname(__FILE__) + '/../lib/depix' unless defined?(Depix)
require "cli_test"

class TestDescribe < Test::Unit::TestCase
  BIN_P = File.dirname(__FILE__) + "/../bin/depix_describe"
  SAMPLE_DPX = File.dirname(__FILE__) + '/samples/E012_P001_L000002_lin.0001.dpx'
  
  def test_app
    s, o, e = CLITest.new(BIN_P).run( File.dirname(__FILE__) + "/samples/gluetools_file_header.dpx")
    assert s.zero?, "Should exit without error"
    assert o.include?("03:09:00:17"), "Should include the timecode"
  end
  
  def test_class
    desc =  Depix::Describe.new.describe(SAMPLE_DPX)
    assert_match(/320/, desc)
    assert_match(/Offset to data for this image element/, desc)
  end
  
end
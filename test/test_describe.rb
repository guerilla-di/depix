require 'test/unit'
require "cli_test"

class TestDescribe < Test::Unit::TestCase
  BIN_P = File.dirname(__FILE__) + "/../bin/depix-describe"
  
  def test_desribe
    s, o, e = CLITest.new(BIN_P).run( File.dirname(__FILE__) + "/samples/gluetools_file_header.dpx")
    assert s.zero?
    assert o.include?("timecode:")
  end
end
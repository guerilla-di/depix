require 'test/unit'
require File.dirname(__FILE__) + '/../lib/depix' unless defined?(Depix)
require "cli_test"

class TestDescribe < Test::Unit::TestCase
  BIN_P = File.dirname(__FILE__) + "/../bin/depix-describe"
  
  def test_desribe
    s, o, e = CLITest.new(BIN_P).run( File.dirname(__FILE__) + "/samples/gluetools_file_header.dpx")
    assert s.zero?, "Should exit without error"
    assert o.include?("time_code : 03:09:00:17")
  end
end
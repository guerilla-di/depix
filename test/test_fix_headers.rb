require 'test/unit'
require File.dirname(__FILE__) + '/../lib/depix' unless defined?(Depix)
require "cli_test"

class TestFixHeaders < Test::Unit::TestCase
  BIN_P = File.dirname(__FILE__) + "/../bin/depix_fix_headers"
  
  def test_app
    flunk
  end
end
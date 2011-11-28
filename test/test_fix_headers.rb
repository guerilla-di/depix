require 'test/unit'
require File.dirname(__FILE__) + '/../lib/depix' unless defined?(Depix)
require "cli_test"

class TestFixHeaders < Test::Unit::TestCase
  BIN_P = File.dirname(__FILE__) + "/../bin/depix_fix_headers"
  
  def test_app
    from_file = File.expand_path(File.dirname(__FILE__) + "/samples/scratch.dpx")
    to_file = File.dirname(from_file) + "/_mod.dpx"
    begin
      FileUtils.cp(from_file, to_file)
      s, o, e = CLITest.new(BIN_P).run(to_file)
      assert s.zero?, "Should exit without error"
    ensure
      File.unlink(to_file)
    end
  end
end
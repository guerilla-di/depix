require File.dirname(__FILE__) + '/../depix'

require 'benchmark'
puts "Reading DPX header 1000 times"
puts Benchmark.measure {
  (0..4).map do
    pid=fork
    if (pid)
    else
      10000.times { Depix::Reader.new.from_file(File.dirname(__FILE__)+"/../../test/samples/026_FROM_HERO_TAPE_5-3-1_MOV.0029.dpx") }
    end
  end
  Process.waitall
}

require File.dirname(__FILE__) + '/../depix'

require 'benchmark'
puts Benchmark.measure {
  45000.times { Depix::Reader.new.from_file(File.dirname(__FILE__)+"/../../test/samples/026_FROM_HERO_TAPE_5-3-1_MOV.0029.dpx") }
}

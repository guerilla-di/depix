require File.dirname(__FILE__) + '/../depix'

require 'benchmark'

iter = 10000

puts "Reading DPX header #{iter} times, all data"
puts Benchmark.measure {
  iter.times { Depix.from_file(File.dirname(__FILE__)+"/../../test/samples/026_FROM_HERO_TAPE_5-3-1_MOV.0029.dpx", false) }
}

puts "Reading DPX header #{iter} times, compact data"
puts Benchmark.measure {
  iter.times { Depix.from_file(File.dirname(__FILE__)+"/../../test/samples/026_FROM_HERO_TAPE_5-3-1_MOV.0029.dpx", true) }
}
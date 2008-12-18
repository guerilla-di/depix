require 'stringio'
require 'rubygems'
require 'timecode'

require File.dirname(__FILE__) + '/depix/structs'

module Depix
  VERSION = '1.0.0'
  BLANK_4, BLANK_2 = 0xFFFFFFFF, 0xFFFF
  
  # Methodic hash - stolen from Camping
  class H < Hash
    # Gets or sets keys in the hash.
    #
    #   @cookies.my_favorite = :macadamian
    #   @cookies.my_favorite
    #   => :macadamian
    #
    def method_missing(m,*a)
        m.to_s=~/=$/?self[$`]=a[0]:a==[]? (self.key?(m.to_sym) ? self[m.to_sym] : super ) : super
    end
    undef id, type
  end

  
  class Reader
    def from_file(path)
      header = File.open(path, 'r') { |f| f.read(Structs.struct_size(Structs::DPX_INFO)) }
      result = deep_parse(StringIO.new(header), Structs::DPX_INFO)
    end
  
    private
  
    def deep_parse(io, structure)
      parsed = {}
      structure.each do | element |
        if element.size == 3
          key, cast, size = element
          parsed[key] = process_cast(cast, io, size, key)
          # debug "Parsed #{key}=#{parsed[key]} (#{cast} #{size})" unless parsed[key].is_a?(H)
         
          # Catch LE-BE
          @big_endian = (parsed[key] == "SDPX") if element[0] == :magic
        elsif element.size == 2
          # skip for now
        end
      end
      H[parsed]
    end
  
    def debug(str)
      puts str
    end
    
    def process_cast(cast_to, io, chunk_size, key)
      # Nested structs get rerouted to deep_parse
      if cast_to.is_a?(Array)
        deep_parse(io, cast_to)
      else # simple types
        data = io.read(chunk_size)
        case true
          when cast_to == String
            unpad(data.unpack("A*").pop)
          when cast_to == Integer
            case chunk_size
              when 4
                v = (@big_endian ? data.unpack("N") : data.unpack("V")).pop
                v == BLANK_4 ? nil : v
              when 2
                v = (@big_endian ? data.unpack("n") : data.unpack("v")).pop
                v == BLANK_2 ? nil : v
            end
          when cast_to == Float
            v = (@big_endian ? data.unpack("g") : data.unpack("f")).pop
            v.nan? ? nil : v
          when cast_to == Timecode
            int = (@big_endian ? data.unpack("N") : data.unpack("V")).pop
            uint_to_tc(int)
        end
      end
    end
  
    def unpad(string)
      string.gsub(0xFF.chr, '').gsub(0xFF.chr, '')
    end
    
    TIME_FIELDS = 7

    def uint_to_tc(timestamp)
      shift = 4 * TIME_FIELDS;
      tc_elements = (0..TIME_FIELDS).map do 
        part = ((timestamp >> shift) & 0x0F)
        shift -= 4
        part
      end.join.scan(/(\d{2})/).flatten.map{|e| e.to_i}
      
      Timecode.at(*tc_elements)
    end
  end
end


if __FILE__ == $0
  require 'benchmark'
# puts Benchmark.measure {
#   45000.times { Depix::Reader.new.from_file(File.dirname(__FILE__)+"/../test/samples/026_FROM_HERO_TAPE_5-3-1_MOV.0029.dpx") }
# }
  res = Depix::Reader.new.from_file(File.dirname(__FILE__)+"/../test/samples/026_FROM_HERO_TAPE_5-3-1_MOV.0029.dpx")
end
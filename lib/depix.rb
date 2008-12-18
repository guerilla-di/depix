require File.dirname(__FILE__) + '/depix/structs'
require 'stringio'
require 'rubygems'
#require 'timecode'

module Depix
  VERSION = '1.0.0'
  
  # Methodic hash - stolen from Camping
  class Meta < Hash
    def method_missing(m,*a)
        m.to_s=~/=$/?self[$`]=a[0]:a==[]?self[m.to_s]:super
    end
    undef id, type
  end
  
  class Reader
    def read_from_file(path)
      hash = deep_parse(File.open(path, 'r'), Structs::DPX_INFO)
      puts hash[:image][:pixels_per_line]
    end
  
    private
  
    def deep_parse(io, structure)
      parsed = {}
      structure.each do | element |
        if element.size == 3
          key, cast, size = element
          parsed[key] = process_cast(cast, io, size, key)
       #   puts "#{key}=#{parsed[key].inspect} - #{cast} (#{size})" unless parsed[key].is_a?(Meta)

          @big_endian = (parsed[key] == "SDPX") if element[0] == :magic
        elsif element.size == 2
          # skip for now
        end
      end
      Meta[parsed]
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
                @big_endian ? data.unpack("N") : data.unpack("V")
              when 2
                @big_endian ? data.unpack("n") : data.unpack("v")
            end
          when cast_to == Float
            @big_endian ? data.unpack("g") : data.unpack("f")
          else
            raise "Ooops - dunno how to cast #{cast_to}"
        end
      end
    end
  
    def unpad(string)
      #string.gsub(/(\377+)/, ' ').gsub(/(\000+)/, ' ').strip
      string.gsub("\000", '').gsub(0xFF.chr, '')
    end
  end
end


if __FILE__ == $0
  Depix::Reader.new.read_from_file(File.dirname(__FILE__)+"/../test/samples/026_FROM_HERO_TAPE_5-3-1_MOV.0029.dpx")
end
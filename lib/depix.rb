require File.dirname(__FILE__) + '/depix/structs'
require 'stringio'
require 'rubygems'
require 'timecode'

module Depix
  VERSION = '1.0.0'
  
  # Methodic hash - stolen from Camping
  class Meta < Hash
    def method_missing(m,*a)
        m.to_s=~/=$/?self[$`]=a[0]:a==[]?self[m.to_s]:super
    end
    undef id, type
  end
  
  def self.read_from_file(path)
    hash = deep_parse(File.open(path, 'r'), Structs::DPX_INFO)
    puts hash.inspect
  end
  
  private
  
  def self.deep_parse(io, structure)
    parsed = {}
    structure.each do | element |
      if element.size == 3
        key, cast, size = element
        parsed[key] = process_cast(cast, io, size, key)
      elsif element.size == 2
        # skip for now
      end
    end
    Meta[parsed]
  end
  
  def self.process_cast(cast_to, io, sizeof_chunk, key)
    # Nested structs get rerouted to deep_parse
    if cast_to.is_a?(Array)
      deep_parse(io, cast_to)
    else # simple types
      data = io.read(sizeof_chunk)
      
      retv = case true
        when cast_to == String
          unpad(data)
        when cast_to == Integer
          data.unpack("I4")
        when cast_to == Float
          data.unpack("F#{Structs::FLOAT}")
        else
          raise "Ooops - dunno how to cast #{cast_to}"
      end
      
      # Little kludgy
      #retv = Timecode.new(retv) if key == :time_code
      
      retv
    end
  end
  
  def self.unpad(string)
    string.gsub(/(\377+)/, ' ').gsub(/(\000+)/, ' ').strip
  end
end


if __FILE__ == $0
  Depix.read_from_file('/Code/tools/ruby_libs/depix/test/samples/026_FROM_HERO_TAPE_5-3-1_MOV.0029.dpx')
end
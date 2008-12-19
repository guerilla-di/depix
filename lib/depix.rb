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
  
  # Reads the metadata
  class Reader

    # Read the header from file (no worries, only the needed number of bytes will be read into memory). Returns a H with the metadata.
    def from_file(path)
      header = File.open(path, 'r') { |f| f.read(Structs::TEMPLATE_LENGTH) }
      deep_parse(header, Structs::DPX_INFO)
    end
    
    # Read the metadata from an in-memory string. Returns a H with the metadata.
    def from_string(str)
      deep_parse(str, Structs::DPX_INFO)
    end
    
    private
  
    def deep_parse(data, structure)
      magic = data[0..3]
      template = (magic == "SDPX") ? Structs::TEMPLATE_BE : Structs::TEMPLATE_LE
      
      result = data.unpack(template).map do |e| 
        case e
          when String
            clean = unpad(e)
            clean.empty? ? nil : clean
          when Integer
            (e == BLANK_2 || e == BLANK_4) ? nil : e
          when Float
            e.nan? ? nil : e
        end
      end
      
      if true # debug
        Structs::TEMPLATE_KEYS.zip(result).each{|k, v| puts "Parsed #{k}:#{v}" unless v.nil? }
      end
      
      self.class.nestify(Structs::TEMPLATE_KEYS, result)
    end
  
    private 
    
    def self.nestify(keys, values)
      auto_hash = H.new do |h,k| 
        h[k] = H.new(&h.default_proc)
      end
      
      keys.each_with_index do |path, idx |
        value = values[idx]
        
        sub, elems = auto_hash, path.split('.')
        while elems.any?
          dir = elems.shift
          dir = dir.to_i if dir =~ /^(\d+)$/
          elems.any? ? (sub = sub[dir]) : (sub[dir] = value)
        end
      end
      
      auto_hash
    end
    
    def unpad(string) # :nodoc:
      string.gsub(0xFF.chr, '').gsub(0xFF.chr, '')
    end
    
    TIME_FIELDS = 7 # :nodoc:

    def uint_to_tc(timestamp)  # :nodoc:
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
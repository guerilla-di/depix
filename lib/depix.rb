require 'stringio'
require 'rubygems'
require 'timecode'

require File.dirname(__FILE__) + '/depix/structs'

module Depix
  VERSION = '1.0.1'
  
  BLANK_2 = 0xFFFF #:nodoc:
  BLANK_4 = 0xFFFFFFFF #:nodoc:
  BLANK_F = 0xFFFFFFFF #:nodoc:
  BLANK_CHAR = 0xFF #:nodoc:
  
  # Methodic hash - stolen from Camping
  class H < Hash
    # Gets or sets keys in the hash.
    #
    #   @cookies.my_favorite = :macadamian
    #   @cookies.my_favorite
    #   => :macadamian
    #
    def method_missing(m,*a)
        m.to_s=~/=$/ ? (self[$`] = a[0]) : (a == [] ? (self.key?(m.to_s) ? self[m.to_s] : super ) : super)
    end
    undef id, type
  end
  
  # Offers convenience access to a few common attributes bypassing the piecemeal structs
  module Synthetics
    def keycode
      [film.id, film.type, film.offset, film.prefix, film.count].compact.join(' ')
    end
    
    def flame_reel
      orientation.device.to_s.scan(/^(\w+)/).to_s
    end
    
    def time_code
      Timecode.from_uint(television.time_code, film.fps)
    end
    
    # Get the name of the transfer function (Linear, Logarithmic, ...)
    def colorimetric
      Structs::COLORIMETRIC.invert[image.image_elements[0].colorimetric]
    end
    
    # Get the name of the compnent type (RGB, YCbCr, ...)
    def component_type
      Structs::COMPONENT_TYPE.invert[image.image_elements[0].descriptor]
    end

  end
  
  # Reads the metadata
  class Reader
    
    class << self
      # Read the header from file (no worries, only the needed number of bytes will be read into memory). Returns a H with the metadata.
      def from_file(path)
        new.from_file(path)
      end

      # Read the metadata from an in-memory string. Returns a H with the metadata.
      def from_string(str)
        new.from_string(str)
      end
      
      # Returns a printable report on all the headers present in the string
      def describe_string(str)
        reader = new
        result = reader.deep_parse(str, Structs::DPX_INFO)
        reader.inform(result)
      end

      # Returns a printable report on all the headers present in the file at the path passed
      def describe_file(path)
        header = File.open(path, 'r') { |f| f.read(Structs::TEMPLATE_LENGTH) }
        describe_string(header)
      end
    end
    
    #:stopdoc:
    def from_file(path)
      header = File.open(path, 'r') { |f| f.read(Structs::TEMPLATE_LENGTH) }
      from_string(header)
    end
    
    def from_string(str) #:nodoc:
      wrap(deep_parse(str, Structs::DPX_INFO))
    end
    
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
      result
    end
    
    def inform(result)
      Structs::TEMPLATE_KEYS.zip(result).map{|k, v| "#{k}:#{v}" unless v.nil? }.compact.join("\n")
    end
    
    def wrap(result)
      eich = self.class.nestify(Structs::TEMPLATE_KEYS, result)
      class << eich; include Synthetics; end
      eich
    end
    
    # FIXME - currently no array handling
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
      string.gsub("\000", '').gsub(0xFF.chr, '')
    end
    
    #:startdoc:
  end
end
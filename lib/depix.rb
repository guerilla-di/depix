require 'stringio'
require 'rubygems'
require 'timecode'

require File.dirname(__FILE__) + '/depix/dict'
require File.dirname(__FILE__) + '/depix/structs'
require File.dirname(__FILE__) + '/depix/compact_structs'
require File.dirname(__FILE__) + '/depix/enums'

module Depix
  VERSION = '1.0.2'
  
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
      COLORIMETRIC.invert[image.image_elements[0].colorimetric]
    end
    
    # Get the name of the compnent type (RGB, YCbCr, ...)
    def component_type
      COMPONENT_TYPE.invert[image.image_elements[0].descriptor]
    end
    
    # Is this DPX file little-endian? This would be an exception, but still useful
    def le?
      file.magic == 'XPDS'
    end
  end
  
  # Reads the metadata
  class Reader
    
    class << self
      # Read the header from file (no worries, only the needed number of bytes will be read into memory). Returns a H with the metadata.
      def from_file(path, compact = false)
        new.from_file(path, compact)
      end

      # Read the metadata from an in-memory string. Returns a H with the metadata.
      def from_string(str, compact = false)
        new.from_string(str, compact)
      end
      
      # Returns a printable report on all the headers present in the string
      def describe_string(str, compact = false)
        reader = new
        result = reader.deep_parse(str, compact)
        reader.inform(result)
      end

      # Returns a printable report on all the headers present in the file at the path passed
      def describe_file(path, compact = false)
        header = File.open(path, 'r') { |f| f.read(DPX.length) }
        describe_string(header, compact)
      end
    end
    
    #:stopdoc:
    def from_file(path, compact)
      header = File.open(path, 'r') { |f| f.read(DPX.length) }
      from_string(header, compact)
    end
    
    def from_string(str, compact) #:nodoc:
      wrap(deep_parse(str, compact))
    end
    
    def deep_parse(data, compact)
      magic = data[0..3]
      struct = compact ? CompactDPX : DPX
      
      template = (magic == "SDPX") ? struct.pattern : make_le(struct.pattern)
      result = struct.consume!(data.unpack(template))
    end
    
    def inform(result)
      Structs::TEMPLATE_KEYS.zip(result).map{|k, v| "#{k}:#{v}" unless v.nil? }.compact.join("\n")
    end
    
    def make_le(pattern)
      pattern.gsub(/n/, "v").gsub(/N/, "V").gsub(/g/, "f")
    end
    
    def wrap(result)
      class << result; include Synthetics; end
      result
    end
    
    def unpad(string) # :nodoc:
      string.gsub("\000", '').gsub(0xFF.chr, '')
    end
    
    #:startdoc:
  end
end
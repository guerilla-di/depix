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
      Timecode.from_uint(television.time_code) #, film.frame_rate)
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
  
  class DPX < Dict
    include Synthetics
  end
  
  # Return a DPX object describing a file at path.
  # The second argument specifies whether you need a compact or a full description
  def self.from_file(path, compact = false)
    Reader.new.from_file(path, compact)
  end
  
  # Return a DPX object describing headers embedded at the start of the string.
  # The second argument specifies whether you need a compact or a full description
  def self.from_string(string, compact = false)
    Reader.new.parse(string, compact)
  end
  
  # Retrurn a formatted description of the DPX file at path. Empty values are omitted.
  def self.describe_file(path)
    Reader.new.from_file(path).describe
  end
  
  class Reader
    
    # Returns a printable report on all the headers present in the file at the path passed
    def describe_file(path, compact = false)
      header = File.open(path, 'r') { |f| f.read(DPX.length) }
      describe_string(header, compact)
    end
    
    def from_file(path, compact)
      header = File.open(path, 'r') { |f| f.read(DPX.length) }
      parse(header, compact)
    end
        
    def parse(data, compact)
      magic = data[0..3]
      struct = compact ? CompactDPX : DPX
      
      template = (magic == "SDPX") ? struct.pattern : make_le(struct.pattern)
      struct.consume!(data.unpack(template))
    end
    
    # Describe a filled DPX structure
    def describe(result)
      result.class.fields.inject([]) do | information, field |
        value = result.send(field.name)
        information.merge!(field.name => (field.is_a?(InnerField) ? describe(value) : value)) if value
        information
      end
    end
    
    # Convert an unpack pattern to LE
    def make_le(pattern)
      pattern.gsub(/n/, "v").gsub(/N/, "V").gsub(/g/, "f")
    end
    
  end
end
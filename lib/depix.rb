require 'stringio'
require 'rubygems'
require 'timecode'

require File.dirname(__FILE__) + '/depix/dict'
require File.dirname(__FILE__) + '/depix/structs'
require File.dirname(__FILE__) + '/depix/compact_structs'
require File.dirname(__FILE__) + '/depix/enums'

module Depix
  VERSION = '1.0.3'
  
  class InvalidHeader < RuntimeError; end
  
  # Offers convenience access to a few common attributes bypassing the piecemeal structs
  module Synthetics
    def keycode
      [film.id, film.type, film.offset, film.prefix, film.count].compact.join(' ')
    end
    
    # Return the flame reel name. The data after the first null byte is not meant to be seen and is used by Flame internally
    # as it seems
    def flame_reel
      orientation.device.split("\000").shift
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
  def self.describe_file(path, compact = false)
    Reader.new.describe_file(path, compact)
  end
  
  class Reader
    
    # Returns a printable report on all the headers present in the file at the path passed
    def describe_file(path, compact = false)
      header = File.open(path, 'r') { |f| f.read(DPX.length) }
      describe_struct(parse(header, false))
    end
    
    def from_file(path, compact)
      header = File.open(path, 'r') { |f| f.read(DPX.length) }
      begin
        parse(header, compact)
      rescue InvalidHeader => e
        raise InvalidHeader, "Invalid header in file #{path}"
      end
    end
    
    # The hear of Depix
    def parse(data, compact)
      magic = data[0..3]
      
      raise InvalidHeader unless %w( SDPX XPDS).include?(magic)
      
      struct = compact ? CompactDPX : DPX
      
      is_be = (magic == "SDPX")
      version_check = FileInfo.only(:magic, :version)
      
      result = begin
        if is_be
          version_check.consume!(data.unpack(version_check.pattern))
        else
          version_check.consume!(data.unpack(make_le(version_check.pattern)))
        end
      rescue ArgumentError
        raise InvalidHeader
      end
      
      raise InvalidHeader unless result.version == "V1.0"
       
      template = is_be ? DPX.pattern : make_le(DPX.pattern)
      struct.consume!(data.unpack(struct.pattern))
    end
    
    # Describe a filled DPX structure
    def describe_struct(result, pad_offset = 0)
      result.class.fields.inject([]) do | info, field |
        value = result.send(field.name)
        parts = []
        if value
          parts << field.desc if field.desc
          parts << if field.is_a?(InnerField)
            describe_struct(value, pad_offset + 1)
          elsif field.is_a?(ArrayField)
            # Exception for image elements
            value = result.image_elements[0...result.number_elements] if field.name == :image_elements
            value.map { | v | v.is_a?(Dict) ? describe_struct(v, pad_offset + 2) : v }
          else
            value
          end
        end
        if parts.any?
          info << parts.join(' ')
        end
        info
      end.map{|e| ('  ' * pad_offset) + e }.join("\n")
    end
    
    # Convert an unpack pattern to LE
    def make_le(pattern)
      pattern.gsub(/n/, "v").gsub(/N/, "V").gsub(/g/, "f")
    end
    
  end
end
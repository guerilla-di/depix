require 'rubygems'
require 'timecode'

require File.dirname(__FILE__) + '/depix/dict'
require File.dirname(__FILE__) + '/depix/structs'
require File.dirname(__FILE__) + '/depix/compact_structs'
require File.dirname(__FILE__) + '/depix/enums'
require File.dirname(__FILE__) + '/depix/reader'
require File.dirname(__FILE__) + '/depix/editor'


module Depix
  VERSION = '1.0.7'
  
  class InvalidHeader < RuntimeError; end
  
  # Offers convenience access to a few common attributes bypassing the piecemeal structs
  module Synthetics
    
    # Get formatted keycode as string, empty elements are omitted
    def keycode
      [film.id, film.type, film.offset, film.prefix, film.count].compact.join(' ')
    end
    
    # Return the flame reel name. The data after the first null byte is not meant to be seen and is used by Flame internally
    # as it seems
    def flame_reel
      orientation.device.split(0x00.chr).shift
    end
    
    # Assign reel name
    def flame_reel=(new_reel)
      orientation.device = new_reel
    end
    
    # Get television.time_code as a Timecode object with a framerate
    def time_code
      Timecode.from_uint(television.time_code) #, film.frame_rate)
    end
    
    # Assign frame rate and timecode from a Timecode object
    def time_code=(new_tc)
      television.time_code, film.frame_rate = new_tc.to_uint, new_tc.fps
    end
    
    # Get the name of the transfer function (Linear, Logarithmic, ...)
    def colorimetric
      COLORIMETRIC.invert[image.image_elements[0].colorimetric]
    end
    
    # Get the name of the compnent type (RGB, YCbCr, ...)
    def component_type
      COMPONENT_TYPE.invert[image.image_elements[0].descriptor]
    end
    
    # Aspect in it's traditional representation (1.77 for 16x9 and so on)
    def aspect
      "%.2f" % (orientation.aspect_ratio[0].to_f / orientation.aspect_ratio[1].to_f)
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
  
  # Return a formatted description of the DPX file at path, showing only synthetic attributes
  def self.describe_brief(path)
    Reader.new.describe_synthetics_of_struct(from_file(path))
  end
  
end
# Offers convenience access to a number of interesting fields of the DPX object
# already decoded into the most usable form (and pulled from a field that you
# won't expect)
module Depix::Synthetics
  
  DEFAULT_DPX_FPS = 25
  
  # Get formatted keycode as string, empty elements are omitted
  def keycode
    [film.id, film.type, film.offset, film.prefix, film.count].compact.join(' ')
  end
  
  # Return the flame reel name. The data after the first null byte is not meant to be seen 
  # and is used by Flame internally
  # as it seems
  def flame_reel
    return nil unless orientation.device
    orientation.device.split(0x00.chr).shift
  end
  
  # Assign reel name
  def flame_reel=(new_reel)
    orientation.device = new_reel
  end
  
  # Get television.time_code as a Timecode object with a framerate.
  # We explicitly use the television frame rate since Northlight
  # writes different rates for television and film time code
  def time_code
    framerates = [television.frame_rate, film.frame_rate, DEFAULT_DPX_FPS]
    framerate = framerates.find{|e| !e.nil? && !e.zero? }
    if television.time_code
      Timecode.from_uint(television.time_code, framerate)
    else
      # Assume frame position
      Timecode.new(film.frame_position, framerate)
    end
  end
  
  # Assign frame rate and timecode from a Timecode object
  def time_code=(new_tc)
    television.time_code, television.frame_rate = new_tc.to_uint, new_tc.fps
  end
  
  # Get the name of the transfer function (Linear, Logarithmic, ...)
  def colorimetric
    Depix::COLORIMETRIC.invert[image.image_elements[0].colorimetric]
  end
  
  # Get the name of the compnent type (RGB, YCbCr, ...)
  def component_type
    Depix::COMPONENT_TYPE.invert[image.image_elements[0].descriptor]
  end
  
  # Aspect in it's traditional representation (1.77 for 16x9 and so on)
  def aspect
    #raise [orientation.aspect_ratio[0].to_f, orientation.aspect_ratio[1].to_f].inspect
    
    "%.2f" % (orientation.aspect_ratio[0].to_f / orientation.aspect_ratio[1].to_f)
  end
  
  # Is this DPX file little-endian?
  def little_endian?
    file.magic == 'XPDS'
  end
  
  def le?
    # $stderr.puts "Depix::Synthetics.le? is deprecated, use little_endian? instead"
    little_endian?
  end
end
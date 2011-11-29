require File.dirname(__FILE__) + '/structs'

module Depix
  CompactInfo = FileInfo.only(
    :magic,
    :ditto_key,
    :filename,
    :timestamp,
    :image_offset 
  )
  
  
  CompactFilmInfo = FilmInfo.only(
    :offset,
    :count,
    :frame_position,
    :frame_id,
    :slate,
    :id,
    :type,
    :prefix,
    :sequence_extent,
    :frame_rate
  )
  
  CompactOrientation = OrientationInfo.only(
    :filename,
    :timestamp
  )
  
  CompactTelevision = TelevisionInfo.only(
    :time_code,
    :user_bits,
    :field_number
  )

  
  # A version of the DPX structure that only accounts for the values that change per frame if the ditto_key is set to 1
  class CompactDPX < Binary::Structure
    inner :file, CompactInfo, :desc => "File information, only frame-transient values"
    
    inner :image, ImageInfo.filler
    
    inner :orientation, OrientationInfo, :desc => "Orientation, only frame-transient values"
    inner :film, CompactFilmInfo, :desc => "Film industry info, only frame-dependent values"
    inner :television, CompactTelevision, :desc => "TV industry info, only frame-dependent values"
  end
end
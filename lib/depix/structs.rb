module Depix
  # Basically a copy of http://trac.imagemagick.org/browser/ImageMagick/trunk/coders/dpx.c
  #
  # Which is a reformulation of http://www.cineon.com/ff_draft.php
  #
  # Which is a preamble to some SMPTE crap that you have to buy for 14 bucks. Or download from http://www.cinesite.com/static/scanning/techdocs/dpx_spec.pdf
  #
  # It's very fragile - in the world of C, everything is fixed length. If Tolstoy wanted to write
  # "War and Peace" in C he would need to know the number of letters ahead. It has good and bad
  # qualities - the good ones being computers go faster like that. The rest are bad parts.
  module Structs
  
  # To avoid fucking up with sizes afterwards
  UINT, FLOAT, USHORT, UCHAR = 4, 4, 2, 1
  
  def self.struct_size(struct_const) #:nodoc:
    struct_const.inject(0){| s, e | s + e[2]}
  end
  
  # Used to distinguish structs from repeated values
  class Struct < Array; end #:nodoc:
  
  COLORIMETRIC = {
      :UserDefined => 0,
      :PrintingDensity => 1,
      :Linear => 2,
      :Logarithmic => 3,
      :UnspecifiedVideo => 4,
      :SMTPE_274M => 5,
      :ITU_R709 => 6,
      :ITU_R601_625L => 7,
      :ITU_R601_525L => 8,
      :NTSCCompositeVideo => 9,
      :PALCompositeVideo => 10,
      :ZDepthLinear => 11,
      :DepthHomogeneous => 12
  }
  
  COMPONENT_TYPE = {
    :Undefined => 0,
    :Red => 1,
    :Green => 2,
    :Blue => 3,
    :Alpha => 4,
    :Luma => 6,
    :ColorDifferenceCbCr => 7,
    :Depth => 8,
    :CompositeVideo => 9,
    :RGB => 50,
    :RGBA => 51,
    :ABGR => 52,
    :CbYCrY422 => 100,
    :CbYACrYA4224 => 101,
    :CbYCr444 => 102,
    :CbYCrA4444 => 103,
    :UserDef2Element => 150,
    :UserDef3Element => 151,
    :UserDef4Element => 152,
    :UserDef5Element => 153,
    :UserDef6Element => 154,
    :UserDef7Element => 155,
    :UserDef8Element => 156,
  }
  
  FILE_INFO = Struct[
    [:magic, String, 4],
    [:image_offset, Integer, UINT],
    
    [:version, String, 8],
    
    [:file_size, Integer, UINT],
    [:ditto_key, Integer, UINT],
    [:generic_size, Integer, UINT],
    [:industry_size, Integer, UINT],
    [:user_size, Integer, UINT],
    
    [:filename, String, 100],
    [:timestamp, String, 24],
    [:creator, String, 100],
    [:project, String, 200],
    [:copyright, String, 200],
    
    [:encrypt_key, Integer, UINT],
    [:reserve, String, 104],
  ]

  FILM_INFO = Struct[
      [:id, String, 2],
      [:type, String, 2],
      [:offset, String, 2],
      [:prefix, String, 6],
      [:count, String, 4],
      [:format, String, 32],
      
      [:frame_position, Integer, UINT],
      [:sequence_extent, Integer, UINT],
      [:held_count, Integer, UINT],
    
      [:frame_rate, Float, FLOAT],
      [:shutter_angle, Float, FLOAT],
      
      [:frame_id, String, 32],
      [:slate, String, 100],
      [:reserve, String, 56],
  ]
  

  IMAGE_ELEMENT = Struct[
     [:data_sign, Integer, UINT],
     [:low_data, Integer, UINT],
     [:low_quantity, Float, FLOAT],
     [:high_data, Integer, UINT],
     [:high_quantity, Float, FLOAT],
     
     # TODO: Autoreplace with enum values. Note: with these we will likely be addressing the enums
     [:descriptor, String, UCHAR],
     [:transfer, String, UCHAR],
     [:colorimetric, String, UCHAR],
     [:bit_size, String, UCHAR],
     
     [:packing, Integer, USHORT],
     [:encoding, Integer, USHORT],
     [:data_offset, Integer, UINT],
     [:end_of_line_padding, Integer, UINT],
     [:end_of_image_padding, Integer, UINT],
     [:description, String, 32],
  ]
  
  IMAGE_ELEMENTS = (0..7).map{|e| [e, IMAGE_ELEMENT, struct_size(IMAGE_ELEMENT)] }
  
  IMAGE_INFO = Struct[
    [:orientation, Integer, USHORT],
    [:number_elements, Integer, USHORT],
    
    [:pixels_per_line, Integer, UINT],
    [:lines_per_element, Integer, UINT],
    
    [:image_elements, IMAGE_ELEMENTS, struct_size(IMAGE_ELEMENTS) ],

    [:reserve, String, 52],
  ]
  
  BORDER = (0..3).map{|s| [s, Integer, USHORT] }

  ASPECT_RATIO = [
    [0, Integer, UINT],
    [1, Integer, UINT],
  ]
  
  ORIENTATION_INFO = Struct[
  
    [:x_offset, Integer, UINT],
    [:y_offset, Integer, UINT],
    
    [:x_center, Float, FLOAT],
    [:y_center, Float, FLOAT],
    
    [:x_size, Integer, UINT],
    [:y_size, Integer, UINT],
    
    [:filename, String, 100],
    [:timestamp, String, 24],
    [:device, String, 32],
    [:serial, String, 32],
    
    [:border, BORDER, struct_size(BORDER)],
    [:aspect_ratio, ASPECT_RATIO, struct_size(ASPECT_RATIO)],
    
    [:reserve, String, 28],
  ]
  
  TELEVISION_INFO = Struct[
    [:time_code, Integer, UINT],
    [:user_bits, Integer, UINT],
    
    [:interlace, String, UCHAR],
    [:field_number, String, UCHAR],
    [:video_signal, String, UCHAR],
    [:padding, String, UCHAR],
    
    [:horizontal_sample_rate, Float, FLOAT],
    [:vertical_sample_rate, Float, FLOAT],
    [:frame_rate, Float, FLOAT],
    [:time_offset, Float, FLOAT],
    [:gamma, Float, FLOAT],
    [:black_level, Float, FLOAT],
    [:black_gain, Float, FLOAT],
    [:break_point, Float, FLOAT],
    [:white_level, Float, FLOAT],
    [:integration_times, Float, FLOAT],
    [:reserve, String, 76],
  ]
  
  USER_INFO = Struct[
    [:id, String, 32],
    [:user_data, Integer, UINT],
  ]
  
  DPX_INFO = Struct[
    [:file, FILE_INFO, struct_size(FILE_INFO)],
    [:image, IMAGE_INFO, struct_size(IMAGE_INFO)],
    [:orientation, ORIENTATION_INFO, struct_size(ORIENTATION_INFO)],
    [:film, FILM_INFO, struct_size(FILM_INFO)],
    [:television, TELEVISION_INFO, struct_size(TELEVISION_INFO)],
    [:user, USER_INFO, struct_size(USER_INFO)],
  ]
  
  # Converts the nexted structs to one template that can be fed to Ruby pack/unpack. This yields
  # some impressive performance improvements (about 1.4 times faster) over reading fields bytewise
  def self.struct_to_template(struct, big_endian)
    keys, template = [], ''
    struct.each do | elem |
      key, cast, size = elem
      pattern = case true
        when cast.is_a?(Struct) # Nested structs
          inner_keys, inner_template = struct_to_template(cast, big_endian)
          # Use a dot as a divider. We will detect it later on and merge into nested hashes
          keys += inner_keys.map{|k| [key, k].join('.') }
          inner_template
        when cast.is_a?(Array) # Repeat values
          inner_keys, inner_template = struct_to_template(cast, big_endian)
          # Use a dot as a divider. We will detect it later on and merge into nested hashes
          keys += inner_keys.map{|k| [key, k].join('.') }
          inner_template
        when cast == Integer || cast == Timecode
          keys << key.to_s
          integer_template(size, big_endian)
        when cast == String
          keys << key.to_s
          "A#{size}"
        when cast == Float
          keys << key.to_s
          big_endian ? "g" : "f"
      end
      
      template << pattern
    end
    [keys, template]
  end
  
  def self.integer_template(size, big_endian) #:nodoc:
    if size == 2
      big_endian ? "n" : "v"
    elsif size == 4
      big_endian ? "N" : "V"
    end
  end
  
  # Shortcuts used to speed up parsing
  TEMPLATE_KEYS, TEMPLATE_BE = struct_to_template(DPX_INFO, true)
  TEMPLATE_LE = struct_to_template(DPX_INFO, false)
  TEMPLATE_LENGTH = struct_size(DPX_INFO)
  
  end
end
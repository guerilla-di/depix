module Depix
  # Basically a copy of http://trac.imagemagick.org/browser/ImageMagick/trunk/coders/dpx.c
  #
  # Which is a reformulation of http://www.cineon.com/ff_draft.php
  #
  # Which is a preamble to some SMPTE crap that you have to buy for 14 bucks. Or download from http://www.cinesite.com/static/scanning/techdocs/dpx_spec.pdf
  module Structs
  
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
  
  #:stopdoc: 
  
  # To avoid fucking up with sizes afterwards
  U32, R32, U16, U8, UCHAR = 4, 4, 2, 1, 1
  
  def self.struct_size(struct_const) #:nodoc:
    struct_const.inject(0){| s, e | s + e[2]}
  end
  
  # Used to distinguish structs from repeated values
  class Struct < Array; end
  
  
  FILE_INFO = Struct[
    [:magic, String, 4],
    [:image_offset, Integer, U32],
    
    [:version, String, 8],
    
    [:file_size, Integer, U32],
    [:ditto_key, Integer, U32],
    [:generic_size, Integer, U32],
    [:industry_size, Integer, U32],
    [:user_size, Integer, U32],
    
    [:filename, String, 100],
    [:timestamp, String, 24],
    [:creator, String, 100],
    [:project, String, 200],
    [:copyright, String, 200],
    
    [:encrypt_key, Integer, U32],
    [:reserve, String, 104],
  ]

  FILM_INFO = Struct[
      [:id, String, 2],
      [:type, String, 2],
      [:offset, String, 2],
      [:prefix, String, 6],
      [:count, String, 4],
      [:format, String, 32],
      
      [:frame_position, Integer, U32],
      [:sequence_extent, Integer, U32],
      [:held_count, Integer, U32],
    
      [:frame_rate, Float, R32],
      [:shutter_angle, Float, R32],
      
      [:frame_id, String, 32],
      [:slate, String, 100],
      [:reserve, String, 56],
  ]
  

  IMAGE_ELEMENT = Struct[
     [:data_sign, Integer, U32],
     [:low_data, Integer, U32],
     [:low_quantity, Float, R32],
     [:high_data, Integer, U32],
     [:high_quantity, Float, R32],
     
     # TODO: Autoreplace with enum values. Note: with these we will likely be addressing the enums
     [:descriptor, Integer, U8],
     [:transfer, Integer, U8],
     [:colorimetric, Integer, U8],
     [:bit_size, Integer, U8],
     
     [:packing, Integer, U16],
     [:encoding, Integer, U16],
     [:data_offset, Integer, U32],
     [:end_of_line_padding, Integer, U32],
     [:end_of_image_padding, Integer, U32],
     [:description, String, 32],
  ]
  
  IMAGE_ELEMENTS = (0..7).map{|e| [e, IMAGE_ELEMENT, struct_size(IMAGE_ELEMENT)] }
  
  IMAGE_INFO = Struct[
    [:orientation, Integer, U16],
    [:number_elements, Integer, U16],
    
    [:pixels_per_line, Integer, U32],
    [:lines_per_element, Integer, U32],
    
    [:image_elements, IMAGE_ELEMENTS, struct_size(IMAGE_ELEMENTS) ],

    [:reserve, String, 52],
  ]
  
  BORDER = (0..3).map{|s| [s, Integer, U16] }

  ASPECT_RATIO = [
    [0, Integer, U32],
    [1, Integer, U32],
  ]
  
  ORIENTATION_INFO = Struct[
  
    [:x_offset, Integer, U32],
    [:y_offset, Integer, U32],
    
    [:x_center, Float, R32],
    [:y_center, Float, R32],
    
    [:x_size, Integer, U32],
    [:y_size, Integer, U32],
    
    [:filename, String, 100],
    [:timestamp, String, 24],
    [:device, String, 32],
    [:serial, String, 32],
    
    [:border, BORDER, struct_size(BORDER)],
    [:aspect_ratio, ASPECT_RATIO, struct_size(ASPECT_RATIO)],
    
    [:reserve, String, 28],
  ]
  
  TELEVISION_INFO = Struct[
    [:time_code, Integer, U32],
    [:user_bits, Integer, U32],
    
    [:interlace, Integer, U8],
    [:field_number, Integer, U8],
    [:video_signal, Integer, U8],
    [:padding, Integer, U8],
    
    [:horizontal_sample_rate, Float, R32],
    [:vertical_sample_rate, Float, R32],
    [:frame_rate, Float, R32],
    [:time_offset, Float, R32],
    [:gamma, Float, R32],
    [:black_level, Float, R32],
    [:black_gain, Float, R32],
    [:break_point, Float, R32],
    [:white_level, Float, R32],
    [:integration_times, Float, R32],
    [:reserve, String, 76],
  ]
  
  USER_INFO = Struct[
    [:id, String, 32],
    [:user_data, Integer, U32],
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
    if size == 1
      big_endian ? "c" : "c"
    elsif size == 2
      big_endian ? "n" : "v"
    elsif size == 4
      big_endian ? "N" : "V"
    end
  end
  
  # Shortcuts used to speed up parsing
  TEMPLATE_KEYS, TEMPLATE_BE = struct_to_template(DPX_INFO, true)
  TEMPLATE_LE = struct_to_template(DPX_INFO, false)
  TEMPLATE_LENGTH = struct_size(DPX_INFO)
  
  #:startdoc:
  end
end
module Depix
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
end
require 'term/ansicolor'

module Depix
  class Reader
    # Parse DPX headers at the start of file
    def from_file(path, compact)
      header = File.open(path, 'r') { |f| f.read(DPX.length) }
      begin
        parse(header, compact)
      rescue InvalidHeader => e
        raise InvalidHeader, "Invalid header in file #{path} - #{e.message}"
      end
    end
  
    # Parse a DPX header (blob of bytes starting at the magic word). The "compact"
    # flag specifies whether a full-blown parser has to be used. This has substantial
    # speed implications. For example:
    # Reading DPX header 1000 times, all data
    #   1.220000   0.080000   1.300000 (  1.898979)
    # Reading DPX header 1000 times, compact data
    #   0.480000   0.050000   0.530000 (  0.766509)
    # This is 2.5 times faster when using compact header form. The compact header form
    # is usually sufficient for reliable sequence data (it only takes fields which change)
    # from one frame to another.
    #
    # When using the compact form a CompactDPX structure will be returned instead of the
    # full-blown DPX structure.
    def parse(data, compact)
      magic = data[0..3]
      raise InvalidHeader, "No magic bytes found at start" unless %w( SDPX XPDS).include?(magic)
      
      is_le = (magic == "XPDS")
      
      version_check = FileInfo.only(:magic, :version)
      begin
        result = is_le ? version_check.apply_le!(data) : version_check.apply!(data)
        raise InvalidHeader, "Unknown version tag #{result.version}" unless result.version =~ /V(\d)\.(\d+)/i
      rescue ArgumentError
        raise InvalidHeader, "Cannot unpack header"
      end
      
      struct = compact ? CompactDPX : DPX
      is_le ? struct.apply_le!(data) : struct.apply!(data)
    end
  end
end
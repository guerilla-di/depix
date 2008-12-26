module Depix
  class Reader
  
    # Returns a printable report on all the headers present in the file at the path passed
    def describe_file(path, compact = false)
      header = File.open(path, 'r') { |f| f.read(DPX.length) }
      struct = parse(header, false)
      describe_struct(struct) + describe_synthetics_of_struct(struct)
    end
  
    def describe_synthetics_of_struct(struct)
      Synthetics.instance_methods.reject{|m| m.include?('=')}.map do | m |
        [m, struct.send(m)].join(' : ')
      end.unshift("============").unshift("\nSynthetic properties").join("\n")
    end
  
    def from_file(path, compact)
      header = File.open(path, 'r') { |f| f.read(DPX.length) }
      begin
        parse(header, compact)
      rescue InvalidHeader => e
        raise InvalidHeader, "Invalid header in file #{path} - #{e.message}"
      end
    end
  
    # The hear of Depix
    def parse(data, compact)
      magic = data[0..3]
    
      raise InvalidHeader, "No magic bytes found at start" unless %w( SDPX XPDS).include?(magic)
    
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
    
      raise InvalidHeader, "Unknown version tag #{result.version}" unless result.version == "V1.0"
     
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
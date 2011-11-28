require 'term/ansicolor'

module Depix
  class Reader
    include Term::ANSIColor
    
    # Returns a printable report on all the headers present in the file at the path passed
    def describe_file(path, compact = false)
      header = File.open(path, 'r') { |f| f.read(DPX.length) }
      struct = parse(header, false)
      describe_struct(struct) + describe_synthetics_of_struct(struct)
    end
  
    def describe_synthetics_of_struct(struct)
      Synthetics.instance_methods.reject{|m| m.to_s.include?('=')}.map do | m |
        [m, struct.send(m)].join(' : ')
      end.unshift("============").unshift("\nSynthetic properties").join("\n")
    end
  
    # Parse DPX headers at the start of file
    def from_file(path, compact)
      header = File.open(path, 'r') { |f| f.read(DPX.length) }
      begin
        parse(header, compact)
      rescue InvalidHeader => e
        raise InvalidHeader, "Invalid header in file #{path} - #{e.message}"
      end
    end
  
    # Parse a DPX header (blob of bytes starting at the magic word)
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
  
    # Describe a filled DPX structure
    def describe_struct(result, pad_offset = 0)
      result.class.fields.inject([]) do | info, field |
        value = result.send(field.name)
        parts = []
        if value
          parts << " " * pad_offset
          parts << red { field.name.to_s }
          parts << "(#{field.desc})" if field.desc
          parts << if field.is_a?(Depix::Binary::Fields::InnerField)
            describe_struct(value, pad_offset + 1)
          elsif field.is_a?(Depix::Binary::Fields::ArrayField)
            value.map { | v | v.is_a?(Depix::Binary::Structure) ? describe_struct(v, pad_offset + 2) : v }
          else
            blue { value.to_s }
          end
        end
        if parts.any?
          info << parts.join(' ')
        end
        info
      end.map{|e| ('  ' * pad_offset) + e }.join("\n")
    end
  
  end
end
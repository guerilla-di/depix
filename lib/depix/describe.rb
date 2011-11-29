# Returns terminal-ready colorized descriptions of DPX headers per file
class Depix::Describe
  include Term::ANSIColor
  
  # Returns a printable report on all the headers present in the file at the path passed
  def describe(path, compact = false)
    struct = Depix.from_file(path, compact)
    describe_struct(struct) + describe_synthetics_of_struct(struct)
  end
  
  def describe_synthetics(path)
    struct = Depix.from_file(path, compact)
    describe_synthetics_of_struct(struct)
  end
  
  def describe_synthetics_of_struct(struct)
    fields = Depix::Synthetics.instance_methods.reject{|m| m.to_s.include?('=')}.map do | m |
      [red{ m.to_s }, blue { struct.send(m).to_s }].join(' : ')
    end
    fields.unshift("============")
    fields.unshift(bold { "\nSynthetic properties" })
    fields.join("\n")
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
          value.map { | v | v.is_a?(Depix::Binary::Structure) ? describe_struct(v, pad_offset + 1) : v }
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
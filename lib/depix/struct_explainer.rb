# Generates an RDoc description of the DPX structs from the structs.rb file
class RdocExplainer < Formatter #:nodoc:
  attr_accessor :io, :attr_template, :struct_template
  
  TPL = <<eof
= DPX header structure description

DPX metadata gets returned as a hash containing other nested hashes. You can address hash keys by symbol, string
and method name

  meta.file.magic # same as meta[:file][:magic]

== Metadata structure

%s
eof

  def initialize
    @padding =  '  '
    @attr_template = "%s* <tt>%s</tt> %s"
    @struct_template = "%s* <tt>%s</tt> hash of"
    @array_template  = "%s* <tt>%s</tt>  (array , %d members):"
    
  end
  
  def get_rdoc_for(struct)
    @io = StringIO.new
    explain_struct(Depix::Structs::DPX_INFO)
    TPL % @io.string
  end
  
  def explain_struct(struct, padding = '') #:nodoc:
    struct.each do | e |
      key, cast, len = e
      if cast.is_a?(Depix::Structs::Struct)
        @io.puts( @struct_template % [padding, key, len])
        explain_struct(cast, padding + @padding)
      elsif cast.is_a?(Array) # Repeats
        @io.puts( @array_template % [padding, key, cast.size])
        inner_struct = cast[0]
        ikey, icast, ilen = inner_struct
        if icast.is_a?(Depix::Structs::Struct)
          explain_struct(icast, padding + @padding)
        else
          @io.puts( @attr_template % [padding, '', icast, ilen])
        end
      else
        @io.puts( @attr_template % [padding, key, cast, len])
      end
    end
  end
end
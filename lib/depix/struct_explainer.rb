# Generates an RDoc description of the DPX structs from the structs.rb file
class Formatter #:nodoc:
  attr_accessor :io, :attr_template, :struct_template
  
  def initialize
    @io, @attr_template, @struct_template, @padding = STDOUT, "%s%s (%s)", "%s%s (which is a hash with the following elements):", '  '
  end
  
  def explain_struct(struct, padding = '') #:nodoc:
    struct.each do | e |
      key, cast, len = e
      unless cast.is_a?(Array)
        @io.puts( @attr_template % [padding, key, cast, len])
      else
        @io.puts( @struct_template % [padding, key, len])
        explain_struct(cast, padding + @padding)
      end
    end
  end
end

class RdocExplainer < Formatter #:nodoc:
  TPL = <<eof
= DPX header structure description

DPX metadata gets returned as a hash containing other nested hashes. You can address hash keys by symbol, string
and method name

  meta.file.magic # same as meta[:file][:magic]

== Metadata structure

%s
eof

  def initialize
    super
    @attr_template = "%s* <tt>%s</tt> %s"
    @struct_template = "%s* <tt>%s</tt> hash of"
  end
  
  def get_rdoc_for(struct)
    @io = StringIO.new
    explain_struct(Depix::Structs::DPX_INFO)
    erb_template = TPL % @io.string
  end
end
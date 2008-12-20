# Generates an RDoc description of the DPX structs from the structs.rb file
class RdocExplainer #:nodoc:
  attr_accessor :io, :attr_template, :struct_template
  
  TPL = <<eof
= DPX header structure description

DPX metadata gets returned as a Depix::DPX object with nested properties.
  
  meta.file.magic # => "SDPX"

== Metadata structure

%s
eof

  def initialize
    @padding =  '  '
    @attr_template = "%s* <tt>%s</tt> %s %s%s"
    @struct_template = "%s* <tt>%s</tt> a %s object"
    @array_template  = "%s* <tt>%s</tt>  (array , %d members):"
    
  end
  
  def get_rdoc_for(struct)
    @io = StringIO.new
    explain_struct(struct)
    TPL % @io.string
  end
  
  include Depix
  
  def explain_struct(struct, padding = '') #:nodoc:
    struct.fields.each do | e |
      if e.is_a?(InnerField)
        
        @io.puts( @struct_template % [padding, e.name, e.rtype])
        explain_struct(e.rtype, padding + @padding)
      
      elsif e.is_a?(ArrayField)
        
        @io.puts( @array_template % [padding, e.name, e.members.size])
        
        inner_struct = e.members[0]
        
        if inner_struct.is_a?(InnerField)
          explain_struct(inner_struct.rtype, padding + @padding)
        end
      else
        explain_attr(padding, e)
      end
    end
  end
  
  def explain_attr(padding, e)
    type_name = e.rtype ? "(#{e.rtype})" : nil
    @io.puts( @attr_template % [padding, e.name, type_name, e.desc, (e.req? ? " - Required" : nil)])
  end
end
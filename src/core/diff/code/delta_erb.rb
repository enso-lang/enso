=begin

Re-implementation of delta tranformation using Ruby's ERB

=end

require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/grammar/code/layout'
require 'core/system/library/schema'
require 'erb'

class DeltaERB

  def self.delta(schema)
    #choose a random file name that probably isn't used. 
    #should double-check just in case...
    tempf_name = "delta-"+rand(10000000).to_s+".schema"
    tempf = File.new(tempf_name, "w")
    tempf.syswrite(gen_delta_as_string(schema))
    tempf.close

    res = Loader.load(tempf_name)
    File.delete(tempf_name)
    return res
  end


  #############################################################################
  #start of private section  
  private
  #############################################################################

  def self.gen_delta_as_string(schema)
    template_string = 
"    primitive int
    primitive str
    class Many end 
    class Keyed end 
    
    class DeltaRef path : str end 
    class Insert_DeltaRef < DeltaRef end 
    class Delete_DeltaRef < DeltaRef end 
    class Modify_DeltaRef < DeltaRef end 
    class Clear_DeltaRef < DeltaRef end
    <%schema.types.each do |type| 
    keyed = IsKeyed?(type)
    poskey = keyed ? ClassKey(type).type.name : 'int'
    supers = ''%>
    <%if type.Primitive? 
      if type.name!='int' and type.name!='str'
        %>primitive <%=type.name%><%
      end
    else
      type.supers.each do |ss|
        supers = (supers.empty? ? ' < D_' : ', D_')+ss.name
      end
    end%>
    class D_<%=type.name%> <%=supers%>
    <%if type.Primitive?%>    val : <%=type.name%>
    <%else
      type.defined_fields.each do |f|
        if !f.traversal and !f.type.Primitive? #is a ref
          if not f.many
            ftype = 'DeltaRef'
          else
            if IsKeyed?(f.type)
              ftype = 'ManyDeltaRef'+ClassKey(f.type).type.name 
            else
              ftype = 'ManyDeltaRefint'
            end
          end
        else
          ftype = 'D_'+f.type.name
      end%>  ! <%=f.name%>: <%=ftype%><%=f.many ? '*':'?'%>
    <%end
    end%>end 
    class Insert_<%=type.name%> < D_<%=type.name%> end 
    class Delete_<%=type.name%> < D_<%=type.name%> end 
    class Modify_<%=type.name%> < D_<%=type.name%> end 
    class Clear_<%=type.name%> < D_<%=type.name%> end 
    class ManyInsert_<%=type.name%> < D_<%=type.name%>, <%=keyed ? 'Keyed' : 'Many'%> pos : <%=poskey%> end 
    class ManyDelete_<%=type.name%> < D_<%=type.name%>, <%=keyed ? 'Keyed' : 'Many'%> pos : <%=poskey%> end 
    class ManyModify_<%=type.name%> < D_<%=type.name%>, <%=keyed ? 'Keyed' : 'Many'%> pos : <%=poskey%> end
    <%if type.Primitive?%>
    class ManyDeltaRef<%=type.name%> < DeltaRef ,Keyed pos : <%=type.name%> end 
    class ManyInsert_DeltaRef<%=type.name%> < ManyDeltaRef<%=type.name%> end 
    class ManyDelete_DeltaRef<%=type.name%> < ManyDeltaRef<%=type.name%> end 
    class ManyModify_DeltaRef<%=type.name%> < ManyDeltaRef<%=type.name%> end 
    class ManyClear_DeltaRef<%=type.name%> < ManyDeltaRef<%=type.name%> end 
    <%end%>
  <%end%>"
    #(supers.empty? ? ' < ' : ', ')+ss.name
    template = ERB.new template_string
    return template.result(binding) # prints "My name is Rasmus" 
  end
  
end
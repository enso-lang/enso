require 'core/semantics/code/combinators'

module FmapMod
  extend Control
  
  #map over the object graph by traversing spine links
  #may not traverse the entire graph if very first node that is called is not a root 
  def execute_?(type, fields, args={})
    fields.each do |k,v|
      f = type.fields[k]
      next unless f.traversal
      if !f.many
        if f.type.Primitive?
          #do nothing
        else
          f.send()
        end
      else
      end
    end
    res
  end
end

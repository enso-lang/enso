require 'core/semantics/code/combinators'

module Fmap
  extend Traverse

  #map over the object graph by traversing spine links
  #may not traverse the entire graph if very first node that is called is not a root 
  def traverse_?(type, fields, args)
    yield
    fields.each do |k,v|
      f = type.all_fields[k]
      next unless f.traversal
      if !f.many
        if f.type.is_a?("Primitive")
          #do nothing
        else
          append(v)
        end
      else
        v.values.each{|obj|append(obj)}
      end
    end
  end
end

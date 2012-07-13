require 'core/semantics/code/combinators'

module Fmap
  #this is technically *not* a map as all it does is go through the entire graph once
  #I would rather call it a 'Functor'(?), and can be used to write maps, folds, filter, etc

  extend Control
  
  operation :fmap

  #map over the object graph by traversing spine links
  #may not traverse the entire graph if very first node that is called is not a root 
  def fmap_?(type, fields, args={})
    fields.each do |k,v|
      f = type.all_fields[k]
      next unless f.traversal
      if !f.many
        if f.type.Primitive?
          #do nothing
        else
          append(v)
        end
      else
        v.values.each{|obj|append(obj)}
      end
    end
    yield
  end

  def __hidden_calls; super+[:fmap]; end
end

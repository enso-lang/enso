
require 'applications/petrinet/code/matrix'


class PetriNet2Matrix

  def petrinet2matrix(petrinet)
    rks = keys_for_class(petrinet, 'Place')
    cks = keys_for_class(petrinet, 'Transition')
    m = Matrix.make({}, rks, cks)
    petrinet.arcs.each do |arc|
      r = key(arc.place)
      c = key(arc.transition)
      m.set!(r, c, arc.multiplicity)
    end
    return m
  end
 
  def keys_for_class(petrinet, klass)
    nodes_by_class(petrinet, klass).map do |x| 
      key(x) 
    end
  end

  def nodes_by_class(petrinet, klass)
    petrinet.nodes.select do |x| 
      x.schema_class.name == klass 
    end
  end

  def key(node)
    node.name.to_sym
  end

end

def petrinet2matrix(petrinet)
  PetriNet2Matrix.new.petrinet2matrix(petrinet)
end


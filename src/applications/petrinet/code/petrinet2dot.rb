


class PetriNet2Dot

  def self.todot(pn, output = $stdout)
    PetriNet2Dot.new.todot(pn, output)
  end

  def todot(pn, output)
    output << "digraph petrinet {\n"
    pn.nodes.each do |n|
      send(n.schema_class.name, n, output)
    end
    pn.arcs.each do |a|
      Arc(a, output)
    end
    output << "}\n"
  end

  def Place(this, output)
    output << "#{this.name} [shape=ellipse]\n"
  end

  def Transition(this, output)
    output << "#{this.name} [shape=box]\n"
  end

  def Arc(this, output)
    if this.multiplicity > 0 then
      output << "#{this.place.name} -> #{this.transition.name}"
    elsif this.multiplicity < 0 then
      output << "#{this.transition.name} -> #{this.place.name}"
    else
      raise "Multiplicity of 0"
    end
    label = this.multiplicity.abs
    if label != 1 then
      output << " [label=#{label}]"
    end
    output << "\n"
  end

  
end

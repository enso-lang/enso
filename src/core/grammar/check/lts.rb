
require 'set'


class Transition
  attr_reader :from, :to, :label

  def initialize(s1, label, s2)
    @from = s1
    @label = label
    @to = s2
  end

  def to_s
    "<#{from}, #{label}, #{to}>"
  end

  def eql?(t)
    self == t
  end
  
  def ==(t)
    from == t.from && to == t.to && label == t.label
  end

  def hash
    1
  end
end

class LTS
  attr_reader :transitions

  def initialize(trans = Set.new)
    if trans.is_a?(Transition) then
      @transitions = Set.new
      @transitions << trans
    else
      @transitions = trans
    end
  end
  
  def +(lts)
    LTS.new(transitions | lts.transitions)
  end

  def states
    transitions.inject(Set.new) do |s, t|
      s << t.from
      s << t.to
    end
  end

  def labels
    transitions.inject(Set.new) do |s, t|
      s << t.label
    end
  end

  def firing_on(label)
    transitions.inject(Set.new) do |s, t|
      if t.label == label
        s << t.from 
      else
        s
      end
    end
  end

  

  def compose(lts)
    tr = Set.new
    transitions.each do |t1|
      lts.transitions.each do |t2|
        if t1.to == t2.from && t1.label == t2.label then
          tr << Transition.new(t1.from, t1.label, t2.to)
        elsif t1.to == t2.from then
          tr << Transition.new(t1.from, t1.label, t2.to)
          tr << Transition.new(t1.from, t2.label, t2.to)
        end
      end
    end
    LTS.new(tr)
  end
  
  def star(c, f)
    opt(c, f) + plus(c, f)
  end
  
  def plus(c, f)
    trs = Set.new
    transitions.each do |tr|
      if tr.label == f then
        trs << Transition.new(tr.to, "e_#{f}", c)
      end
    end
    self + LTS.new(trs)
  end
  
  def opt(c, f)
    self + LTS.new(Transition.new(c, "e_#{f}", c))
  end
  
  def ==(lts)
    transitions == lts.transitions
  end
  
  def to_s
    "{#{transitions.to_a.join(', ')}}"
  end

  def to_dot(out = '')
    out << "digraph bla {\n"
    states = transitions.flat_map do |t|
      [t.from, t.to]
    end.uniq
    states.each_with_index do |s, i|
      out << "n_#{i} [label=\"#{s.to_s.gsub('"', '\\"')}\"]\n"
    end
    transitions.each do |tr|
      out << "n_#{states.index(tr.from)} -> n_#{states.index(tr.to)} [label=\"#{tr.label}\"]\n"
    end
    out << "}\n"
    return out
  end
    

  private

  def closure(f)
    trs = transitions.inject(Set.new) do |set, tr|
      if tr.label == f then
        set << yield(tr)
      else
        set
      end
    end
    LTS.new(trs | transitions)
  end

end

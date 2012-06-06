

require 'core/grammar/check/lts'
require 'set'


def bisim(lts)
  part = Set.new([lts.states])
  split = lts.labels.map do |l|
    [l, lts.states]
  end
  while !split.empty? do
    a, c = split.shift
    #puts "(a, C) = (#{a}, {#{c.to_a.join(', ')}})"
    old = part
    part = refine_p(lts, part, a, c)
    (part - old).each do |s|
      lts.labels.each do |l|
        split << [l, s]
      end
    end
    split.uniq!
  end
  return part
end

def refine_p(lts, part, a, c)
  part.inject(Set.new) do |cur, b|
    cur + refine(lts, b, a, c)
  end
end

def refine(lts, b, a, c)
  pre = Set.new
  lts.transitions.each do |tr|
    pre << tr.from if tr.label == a && c.include?(tr.to)
  end
  Set.new([b & pre, b - pre]) - Set.new([Set.new])
end


if __FILE__ == $0 then
  lts1 = LTS.new
  lts1.transitions << Transition.new('s0', 'a', 's1')
  lts1.transitions << Transition.new('s1', 'g', 's3')
  lts1.transitions << Transition.new('s1', 'b', 's2')
  lts1.transitions << Transition.new('s3', 'd', 's0')

  lts2 = LTS.new
  lts2.transitions << Transition.new('t0', 'a', 't1')
  lts2.transitions << Transition.new('t1', 'b', 't2')
  lts2.transitions << Transition.new('t0', 'a', 't4')
  lts2.transitions << Transition.new('t4', 'g', 't3')
  lts2.transitions << Transition.new('t3', 'd', 't0')

  lts = lts1 + lts2 # NB: should be disjoint union on states.
  
  part = bisim(lts)

  puts "PARTITION RESULT: "
  part.each do |set|
    puts "\t#{set.to_a.join(', ')}"
  end

end


    

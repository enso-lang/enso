

require 'core/system/load/load'
require 'core/grammar/code/layout'

require 'applications/petrinet/code/petrinet2matrix'
require 'applications/petrinet/code/petrinet2dot'

p = Loader.load('example.petrinet')
g = Loader.load('petrinet.grammar')

DisplayFormat.print(g, p)

m = petrinet2matrix(p)

puts m


File.open('bla.dot', 'w') do |f|
  PetriNet2Dot.todot(p, f)
end





require 'core/system/load/load'
require 'core/grammar/code/layout'

require 'applications/petrinet/code/petrinet2matrix'

p = Loader.load('example.petrinet')
g = Loader.load('petrinet.grammar')

DisplayFormat.print(g, p)

m = petrinet2matrix(p)

puts m



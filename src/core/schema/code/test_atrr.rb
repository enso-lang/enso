

require 'core/system/load/load'
require 'core/grammar/code/layout'

sg = Loader.load('schema.grammar')
gg = Loader.load('grammar.grammar')

x = Loader.load('attr-schema.schema')
ag = Loader.load('attr-schema.grammar')

#DisplayFormat.print(sg, x)

#puts "GRAMMAR"
DisplayFormat.print(gg, ag)


repmin_s = Loader.load('repmin.schema')
repmin_g = Loader.load('repmin.grammar')
ex = Loader.load('example.repmin')

attr = Loader.load('repmin.attr-schema')

require 'core/schema/tools/union'

attr2 = union(attr, repmin_s)

DisplayFormat.print(ag, attr2)


# NB:
ex = Copy.new(Factory.new(attr2)).copy(ex)

Print.print(ex)

require 'core/schema/code/eval-attr'

include AttributeSchema


rm = EvalAttr.eval(ex, 'repmin', Factory.new(attr2))

p rm


puts "FROM"
DisplayFormat.print(repmin_g, ex)

puts "RESULT"
DisplayFormat.print(repmin_g, rm)


#############################



ss = Loader.load('schema.schema')
schema2graph_ag = Loader.load('schema-graph.attr-schema')
graph_schema = Loader.load('graph.schema')
attr_schema = Loader.load('attr-schema.schema')
schema2graph = union(union(schema2graph_ag, ss), graph_schema)

DisplayFormat.print(ag, schema2graph)

a_schema = Copy.new(Factory.new(schema2graph)).copy(ss)


graph_grammar = Loader.load('graph.grammar')

to_graph = EvalAttr.eval(a_schema, 'graph', Factory.new(graph_schema))

DisplayFormat.print(graph_grammar, to_graph)

Print.print(to_graph)

#DisplayFormat.print(ag, a_schema)


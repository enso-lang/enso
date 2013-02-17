require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/grammar/render/layout'
require 'core/diff/code/delta'
require 'core/diff/code/diff'
require 'core/diff/code/patch'
require 'core/schema/code/factory'

point_schema = Load::load('diff-point.schema')
point_grammar = Load::load('diff-point.grammar')

p1 = Load::load('diff-test1.diff-point')
DisplayFormat.print(point_grammar, p1)

p2 = Load::load('diff-test2.diff-point')
DisplayFormat.print(point_grammar, p2)

#DisplayFormat.print(Load::load('schema.grammar'), point_schema)
#deltaCons = DeltaTransform.new.delta(point_schema)
#DisplayFormat.print(Load::load('schema.grammar'), deltaCons)
#DisplayFormat.print(Load::load('deltaschema.grammar'), deltaCons)

res = Diff.new.diff(point_schema, p1, p2)

p3 = Patch.patch!(p1, res)

puts "Result of p3 = patch!(p1, diff(p1, p2))"
puts "p1="
DisplayFormat.print(point_grammar, p1)
puts "p2="
DisplayFormat.print(point_grammar, p2)
puts "p3="
DisplayFormat.print(point_grammar, p3)

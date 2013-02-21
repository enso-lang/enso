require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/grammar/render/layout'
require 'core/diff/code/delta'
require 'core/diff/code/diff'
require 'core/diff/code/patch'
require 'core/system/library/schema'


point_schema = Load::load('diff-point.schema')
point_grammar = Load::load('diff-point.grammar')
point_schema = Load::load('deltaschema.schema')

p1 = Load::load('diff-test1.diff-point')
#DisplayFormat.print(point_grammar, p1)

p2 = Load::load('diff-test2.diff-point')
#DisplayFormat.print(point_grammar, p2)

# test creation of delta schema

deltaCons = DeltaTransform.new.delta(point_schema)



=begin
DisplayFormat.print(Load::load('schema.grammar'), point_schema)
deltaCons = DeltaTransform.new.delta(point_schema)
DisplayFormat.print(Load::load('schema.grammar'), deltaCons)
=end
=begin
res = Diff.new.diff(point_schema, p1, p2)
p3 = Patch.patch!(p1, res)
puts Equals.new.equals2(p2, p3)
=end
=begin
puts "Result of p3 = patch!(p1, diff(p1, p2))"
puts "p1="
Layout::DisplayFormat.print(point_grammar, p1)
puts "p2="
Layout::DisplayFormat.print(point_grammar, p2)
puts "p3="
Layout::DisplayFormat.print(point_grammar, p3)
=end

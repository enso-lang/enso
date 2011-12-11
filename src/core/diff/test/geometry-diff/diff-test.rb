require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/grammar/render/layout'
require 'core/diff/code/delta'
require 'core/diff/code/diff'
require 'core/diff/code/patch'
require 'core/system/library/schema'


point_schema = Loader.load('diff-point.schema')
point_grammar = Loader.load('diff-point.grammar')
point_schema = Loader.load('deltaschema.schema')

p1 = Loader.load('diff-test1.diff-point')
#DisplayFormat.print(point_grammar, p1)

p2 = Loader.load('diff-test2.diff-point')
#DisplayFormat.print(point_grammar, p2)

# test creation of delta schema

deltaCons = DeltaTransform.new.delta(point_schema)



=begin
DisplayFormat.print(Loader.load('schema.grammar'), point_schema)
deltaCons = DeltaTransform.new.delta(point_schema)
DisplayFormat.print(Loader.load('schema.grammar'), deltaCons)
=end
=begin
res = Diff.new.diff(point_schema, p1, p2)
p3 = Patch.patch!(p1, res)
puts Equals.new.equals2(p2, p3)
=end
=begin
puts "Result of p3 = patch!(p1, diff(p1, p2))"
puts "p1="
DisplayFormat.print(point_grammar, p1)
puts "p2="
DisplayFormat.print(point_grammar, p2)
puts "p3="
DisplayFormat.print(point_grammar, p3)
=end

require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/grammar/render/layout'

point_schema = Load::load('diff-point.schema')
point_grammar = Load::load('diff-point.grammar')

puts "-"*50

f = ManagedData.new(point_schema)
p = f.Point(3,4)
Print.print(p)

puts "-"*50

p2 = Load::load('test.diff-point')
DisplayFormat.print(point_grammar, p2)


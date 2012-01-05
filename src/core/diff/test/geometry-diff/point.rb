require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/grammar/render/layout'

point_schema = Loader.load('diff-point.schema')
point_grammar = Loader.load('diff-point.grammar')

puts "-"*50

f = ManagedData::Factory.new(point_schema)
p = f.Point(3,4)
Print.print(p)

puts "-"*50

p2 = Loader.load('test.diff-point')
DisplayFormat.print(point_grammar, p2)


require 'core/system/load/load'
require 'core/grammar/render/layout'
require 'core/schema/tools/union'

point_schema = Load::load('point.schema')
point_grammar = Load::load('point.grammar')

puts Load::load('schema.schema')

puts "-"*50

f = Factory::SchemaFactory.new(point_schema)
p = f.Point(3,4)

puts "-"*50

p1 = Load::load('point1.point')
str = ""
Layout::DisplayFormat.print(point_grammar, p1, str)
puts str
puts p1.lines["Flamingo"].label

p2 = Load::load('point2.point')
str = ""
Layout::DisplayFormat.print(point_grammar, p2, str)
puts str
puts p2.lines["Stork"].label

p12 = Union.union(p1, p2)
str = ""
Layout::DisplayFormat.print(point_grammar, p12, str)
puts str

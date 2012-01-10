require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/grammar/render/layout'

point_schema = Loader.load('point.schema')
point_grammar = Loader.load('point.grammar')

puts "-"*50

f = ManagedData::Factory.new(point_schema)
p = f.Point(3,4)
Print.print(p)

puts "-"*50

p2 = Loader.load('point1.point')
str = ""
DisplayFormat.print(point_grammar, p2, 80, str)
puts str


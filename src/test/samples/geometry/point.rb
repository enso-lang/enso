require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/grammar/render/layout'
=begin
puts "\n\n\n\nss\n--------------------------"
Print.print(Loader.load('schema.schema'))
puts "\n\n\n\nsg\n--------------------------"
Print.print(Loader.load('schema.grammar'))
puts "\n\n\n\ngs\n--------------------------"
Print.print(Loader.load('grammar.schema'))
puts "\n\n\n\ngg\n--------------------------"
Print.print(Loader.load('grammar.grammar'))
=end
point_schema = Loader.load('point.schema')
point_grammar = Loader.load('point.grammar')

puts "-"*50

f = ManagedData::Factory.new(point_schema)
p = f.Point(3,4)

puts "-"*50

p2 = Loader.load('point1.point')
str = ""
DisplayFormat.print(point_grammar, p2, 80, str)
puts str
puts p2.drawings['Drawing1'].shapes[0].is_straight

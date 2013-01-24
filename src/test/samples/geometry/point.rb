require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/grammar/render/layout'
require 'core/schema/tools/copy'
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

Print.print Loader.load('schema.schema')

puts "-"*50

f = ManagedData.new(point_schema)
p = f.Point(3,4)

puts "-"*50

p1 = Loader.load('point1.point')
str = ""
DisplayFormat.print(point_grammar, p1, 80, str)
puts str
puts p1.drawings['Drawing1'].shapes[0].is_straight

p2 = Loader.load('point2.point')
str = ""
DisplayFormat.print(point_grammar, p2, 80, str)
puts str
puts p2.drawings['Drawing2'].shapes[0].is_straight

p12 = union(p1, p2)
str = ""
DisplayFormat.print(point_grammar, p12, 80, str)
puts str

require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/grammar/render/layout'
require 'core/schema/tools/copy'
=begin
puts "\n\n\n\nss\n--------------------------"
Print.print(Load::load('schema.schema'))
puts "\n\n\n\nsg\n--------------------------"
Print.print(Load::load('schema.grammar'))
puts "\n\n\n\ngs\n--------------------------"
Print.print(Load::load('grammar.schema'))
puts "\n\n\n\ngg\n--------------------------"
Print.print(Load::load('grammar.grammar'))
=end
point_schema = Load::load('point.schema')
point_grammar = Load::load('point.grammar')

Print.print Load::load('schema.schema')

puts "-"*50

f = ManagedData.new(point_schema)
p = f.Point(3,4)

puts "-"*50

p1 = Load::load('point1.point')
str = ""
DisplayFormat.print(point_grammar, p1, 80, str)
puts str
puts p1.drawings['Drawing1'].shapes[0].is_straight

p2 = Load::load('point2.point')
str = ""
DisplayFormat.print(point_grammar, p2, 80, str)
puts str
puts p2.drawings['Drawing2'].shapes[0].is_straight

p12 = union(p1, p2)
str = ""
DisplayFormat.print(point_grammar, p12, 80, str)
puts str

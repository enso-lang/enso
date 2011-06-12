
require 'core/diagram/code/constraints'

x = Variable.new(:x, 5)
y = Variable.new(:y, 3)
z = Variable.new(:z)
z >= x
z >= y
w = x + y

puts "(#{x.value}, #{y.value})"
puts " max=#{z.value} add=#{w.value}"
x.value = 2
puts "(#{x.value}, #{y.value})"
puts "  max=#{z.value} add=#{w.value}"
x.value = 1
y.value = 1
puts "(#{x.value}, #{y.value})"
puts "  max=#{z.value} add=#{w.value}"


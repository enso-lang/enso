
require 'core/diagram/code/constraints'

x = Variable.new(:x, 5)
y = Variable.new(:y, 3)
z = Variable.compute(:z, [x, y], &:min)
w = Variable.compute(:w, x, y, &:+)

puts "(#{x.value}, #{y.value})"
puts " min=#{z.value} add=#{w.value}"
x.value = 2
puts "(#{x.value}, #{y.value})"
puts "  min=#{z.value} add=#{w.value}"
x.value = 1
y.value = 1
puts "(#{x.value}, #{y.value})"
puts "  min=#{z.value} add=#{w.value}"

a = Variable.new(:a, 10)
b = Variable.new(:b, nil)
c = Variable.new(:c, nil)
x = Variable.new(:x, nil)
Equality.new(a, [:+, b, 2])
Equality.new([:-, a, c], [:+, b, 2])
Equality.new(x, [:+, b, [:/, c, 2]])
puts "a=#{a.value}, b=#{b.value}, c=#{c.value}, x=#{x.value}"



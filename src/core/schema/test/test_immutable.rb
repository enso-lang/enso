require 'core/schema/code/immutable'

require 'core/system/load/load'
require 'core/system/library/schema'


s = Load::load('point.schema')

f = ImmutableFactory.new(s)

a = f.Point2D(3,4)

puts "#{a.x}, #{a.y}"
  
begin 
  a.z
rescue => e
  puts "Correct response is ERROR: #{e}"
end  

begin
  f.Point2D(3)
rescue => e
  puts "Correct response is ERROR: #{e}"
end  

b = f.Point2D(9,-2)
c = f.Point2D(-4, 0)


l = f.Line("test", [a, b, c])

puts "LINE: #{l} #{l.len}"

l.points.each do |p|
  puts "  * #{p}"
end


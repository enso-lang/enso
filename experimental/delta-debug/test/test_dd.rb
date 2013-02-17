require '../experimental/delta-debug/test/testcase.rb'
require '../experimental/delta-debug/code/deltadebug.rb'

# simple test case to ensure that the point (5,5) is not painted
# dd2 violates this because Drawing2 has a line (1,3)-(9,7) that passes thru (5,5)

# The smallest change that can correct this is to modify EITHER coordinate in
# the second point to its original values, ie.
# EITHER mod-(9,-) to change (1,3)-(7,8) to (1,3)-(9,8)
# OR     mod-(-,7) to change (1,3)-(7,8) to (1,3)-(7,7)
# actually, BOTH solutions are misleading, as the whole point needs to be changed
# but this is an inherent weakness of delta-debugging's blackbox approach

# However, due to the quirks in the matching algorithm (unable to match keyless pts)
# the modification on the point was recorded as an insert + delete. Thus the final
# returned result is add-(9,7)

# we can also attempt to localize the bug without a baseline model

proc = Proc.new do |*args|
  testcase(*args)
end

puts "\nComparing dd1 and dd2..."
res = DeltaDebug.new(proc).dd(Load::load('dd1.point'), Load::load('dd2.point'))
puts "Failure-inducing change:"
Print.print(res)

puts "\nComparing dd0 and dd2..."
factory = Factory::new(Load::load('point.schema'))
null = factory.Canvas
res = DeltaDebug.new(proc).dd(null, Load::load('dd2.point'))
puts "Failure-inducing change:"
Print.print(res)


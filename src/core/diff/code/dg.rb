

require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/grammar/render/layout'
require 'core/diff/code/delta_erb'
require 'core/diff/code/diff'
require 'core/diff/code/patch'
require 'core/system/library/schema'



point_schema = Load::load('diff-point.schema')
point_grammar = Load::load('diff-point.grammar')
schema_grammar = Load::load('schema.grammar')
delta_point_grammar = Load::load('delta-point.grammar')



delta_point_schema = DeltaERB.delta(point_schema)
File.open('delta-point.schema', 'w') do |f|
  Layout::DisplayFormat.print(schema_grammar, delta_point_schema, f)
end

p1 = Load::load('diff-test1.diff-point')
DisplayFormat.print(point_grammar, p1)

p2 = Load::load('diff-test2.diff-point')
DisplayFormat.print(point_grammar, p2)

delta = diff(p1, p2)

# puts delta.to_s

Print.print(delta)

File.open('flamingo.delta-point', 'w') do |f|
  Layout::DisplayFormat.print(delta_point_grammar, delta, f)
end

x = Load::load('flamingo.delta-point')

DisplayFormat.print(delta_point_grammar, x)

puts Equals.equals(x, delta)



require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/grammar/render/layout'
require 'core/diff/code/delta_erb'
require 'core/diff/code/diff'
require 'core/diff/code/patch'
require 'core/system/library/schema'



point_schema = Loader.load('diff-point.schema')
point_grammar = Loader.load('diff-point.grammar')
schema_grammar = Loader.load('schema.grammar')
delta_point_grammar = Loader.load('delta-point.grammar')



delta_point_schema = DeltaERB.delta(point_schema)
File.open('delta-point.schema', 'w') do |f|
  DisplayFormat.print(schema_grammar, delta_point_schema, 80, f)
end

p1 = Loader.load('diff-test1.diff-point')
DisplayFormat.print(point_grammar, p1)

p2 = Loader.load('diff-test2.diff-point')
DisplayFormat.print(point_grammar, p2)

delta = diff(p1, p2)

# puts delta.to_s

Print.print(delta)

File.open('flamingo.delta-point', 'w') do |f|
  DisplayFormat.print(delta_point_grammar, delta, 80, f)
end

x = Loader.load('flamingo.delta-point')

DisplayFormat.print(delta_point_grammar, x)

puts Equals.equals(x, delta)

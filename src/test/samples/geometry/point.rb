require 'core/grammar/code/parse'
require 'core/system/boot/grammar_grammar'
require 'core/schema/tools/print'
require 'core/grammar/code/layout'

grammar_grammar = GrammarGrammar.grammar
schema_grammar = CPSParser.load('core/schema/models/schema.grammar', grammar_grammar, GrammarSchema.schema)

point_schema = CPSParser.load('test/samples/geometry/point.schema', schema_grammar, SchemaSchema.schema)

point_grammar = CPSParser.load('test/samples/geometry/point.grammar', grammar_grammar, GrammarSchema.schema)

f = Factory.new(point_schema)

p = f.Point(3,4)

puts "-"*50

Print.print(p)

puts "-"*50

p2 = CPSParser.load('test/samples/geometry/point.data', point_grammar, point_schema)

puts "-"*50

DisplayFormat.print(point_grammar, p2)


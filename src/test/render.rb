  require 'core/grammar/render/layout'
  
  point_grammar = Loader.load('point.grammar')
  point1 = Loader.load('point1.point')

#puts "----- POINT -----"
#  DisplayFormat.print(point_grammar, point1)
  
  schema_grammar = Loader.load('schema.grammar')
  grammar_grammar = Loader.load('grammar.grammar')
  grammar_schema = Loader.load('grammar.schema')
  schema_schema = Loader.load('schema.schema')

#puts "----- POINT GRAMMAR -----"
  DisplayFormat.print(grammar_grammar, point_grammar)

#puts "----- SCHEMA GRAMMAR -----"
#  DisplayFormat.print(grammar_grammar, schema_grammar)
#puts "----- GRAMMAR GRAMMAR -----"
#  DisplayFormat.print(grammar_grammar, grammar_grammar)
#puts "----- GRAMMAR SCHEMA -----"
#  DisplayFormat.print(schema_grammar, grammar_schema)
#puts "----- SCHEMA SCHEMA -----"
#  DisplayFormat.print(schema_grammar, schema_schema)
  
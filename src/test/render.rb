  require 'core/grammar/render/layout'
  
  point_grammar = Load::load('point.grammar')
  point1 = Load::load('point1.point')

#puts "----- POINT -----"
#  Layout::DisplayFormat.print(point_grammar, point1)
  
  schema_grammar = Load::load('schema.grammar')
  grammar_grammar = Load::load('grammar.grammar')
  grammar_schema = Load::load('grammar.schema')
  schema_schema = Load::load('schema.schema')

#puts "----- POINT GRAMMAR -----"
  Layout::DisplayFormat.print(grammar_grammar, point_grammar)

#puts "----- SCHEMA GRAMMAR -----"
#  Layout::DisplayFormat.print(grammar_grammar, schema_grammar)
#puts "----- GRAMMAR GRAMMAR -----"
#  Layout::DisplayFormat.print(grammar_grammar, grammar_grammar)
#puts "----- GRAMMAR SCHEMA -----"
#  Layout::DisplayFormat.print(schema_grammar, grammar_schema)
#puts "----- SCHEMA SCHEMA -----"
#  Layout::DisplayFormat.print(schema_grammar, schema_schema)
  
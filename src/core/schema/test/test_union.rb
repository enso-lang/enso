
require 'core/schema/tools/union'

  gs = Load::load('grammar.schema')
  gg = Load::load('grammar.grammar')
  ss = Load::load('schema.schema')
  sg = Load::load('schema.grammar')
  
  require 'core/schema/tools/print'
  
  result = Union(Factory::new(ss), ss, gs)
  #Print::Print.print(result)
  Layout::DisplayFormat.print(sg, result)
  puts "-"*50
  
  result = Union(Factory::new(gs), sg, gg)
  #Print::Print.print(result)
  Layout::DisplayFormat.print(gg, result)

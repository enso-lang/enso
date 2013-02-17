
require 'core/schema/tools/union'

  gs = Load::load('grammar.schema')
  gg = Load::load('grammar.grammar')
  ss = Load::load('schema.schema')
  sg = Load::load('schema.grammar')
  
  require 'core/schema/tools/print'
  
  result = Union(ManagedData.new(ss), ss, gs)
  #Print.print(result)
  DisplayFormat.print(sg, result)
  puts "-"*50
  
  result = Union(ManagedData.new(gs), sg, gg)
  #Print.print(result)
  DisplayFormat.print(gg, result)

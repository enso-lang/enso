
require 'core/schema/tools/union'
require 'core/system/load/load'
require 'core/grammar/render/layout'

  gs = Load::load('grammar.schema')
  gg = Load::load('grammar.grammar')
  ss = Load::load('schema.schema')
  sg = Load::load('schema.grammar')
  
  require 'core/schema/tools/print'
  
  result = Union.union(ss, gs)
  #Print::Print.print(result)
  Layout::DisplayFormat.print(sg, result)
  puts "-"*50
  
  result = Union.union(sg, gg)
  #Print::Print.print(result)
  Layout::DisplayFormat.print(gg, result)

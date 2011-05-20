
require 'core/schema/tools/union'

  gs = Loader.load('grammar.schema')
  gg = Loader.load('grammar.grammar')
  ss = Loader.load('schema.schema')
  sg = Loader.load('schema.grammar')
  
  require 'core/schema/tools/print'
  
  result = Union(Factory.new(ss), ss, gs)
  #Print.print(result)
  DisplayFormat.print(sg, result)
  puts "-"*50
  
  result = Union(Factory.new(gs), sg, gg)
  #Print.print(result)
  DisplayFormat.print(gg, result)

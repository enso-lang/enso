

require 'core/system/load/load'
require 'core/grammar/code/layout'

wxs = Loader.load('web.schema')
sg = Loader.load('schema.grammar')

DisplayFormat.print(sg, wxs)

wxg = Loader.load('web.grammar')
gg = Loader.load('grammar.grammar')

DisplayFormat.print(gg, wxg)

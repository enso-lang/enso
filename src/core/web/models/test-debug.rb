
require 'core/system/load/load'
require 'core/grammar/render/layout'

x = Loader.load('debug.schema')
g = Loader.load('schema.grammar')

DisplayFormat.print(g, x)


require 'core/system/load/load'
require 'core/grammar/render/layout'

x = Load::load('debug.schema')
g = Load::load('schema.grammar')

DisplayFormat.print(g, x)

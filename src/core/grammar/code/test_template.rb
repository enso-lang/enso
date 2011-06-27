

require 'core/system/load/load'
require 'core/schema/tools/union'
require 'core/schema/code/factory'
require 'core/grammar/code/layout'

tg = Loader.load('grammar-template.grammar')
ss = Loader.load('schema.schema')
sg = Loader.load('schema.grammar')

sf = Factory.new(ss)

exp = Loader.load('template.schema')

gts = Loader.load('grammar-template.schema')

gts_exp = Union(sf, exp, gts)
DisplayFormat.print(sg, gts_exp)

#ex = Loader.load('example.grammar-template')

DisplayFormat.print(tg, ex)

p tg



require 'core/system/load/load'
require 'core/schema/tools/print'

x = Loader.load('rules.path')

Print.print(x)

require 'core/grammar/code/layout'

g = Loader.load('grammar.grammar')




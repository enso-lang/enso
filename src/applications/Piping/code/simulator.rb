
require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/grammar/render/layout'

foo = Loader.load('boiler.piping')

system_schema = Loader.load('genealogy.schema')
system_grammar = Loader.load('genealogy.grammar')

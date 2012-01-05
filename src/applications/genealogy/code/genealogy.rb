require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/grammar/render/layout'

genealogy_schema = Loader.load('genealogy.schema')
genealogy_grammar = Loader.load('genealogy.grammar')

f = ManagedData::Factory.new(genealogy_schema)

#tore = f.Person("id40", "Tore")
#martin = f.Person("id68", "Martin", tore)
#gannholm = f.Genealogy( "gannholm", [tore, martin])

#Print.print(gannholm)

#DisplayFormat.print(genealogy_grammar, gannholm)

puts "-"*50
gannholm2 = Loader.load('test.genealogy')
Print.print(gannholm2)
puts "-"*50
DisplayFormat.print(genealogy_grammar, gannholm2)

require 'core/grammar/code/parse'
require 'core/system/boot/grammar_grammar'
require 'core/schema/tools/print'
require 'core/grammar/code/layout'

grammar_grammar = GrammarGrammar.grammar
schema_grammar = CPSParser.load('core/schema/models/schema.grammar', grammar_grammar, GrammarSchema.schema)

genealogy_schema = CPSParser.load('applications/genealogy/models/genealogy.schema', schema_grammar, SchemaSchema.schema)

genealogy_grammar = CPSParser.load('applications/genealogy/models/genealogy.grammar', grammar_grammar, GrammarSchema.schema)

f = Factory.new(genealogy_schema)

#tore = f.Person("id40", "Tore")
#martin = f.Person("id68", "Martin", tore)
#gannholm = f.Genealogy( "gannholm", [tore, martin])

#Print.print(gannholm)

#DisplayFormat.print(genealogy_grammar, gannholm)

puts "-"*50
gannholm2 = CPSParser.load('applications/genealogy/genealogy.data', genealogy_grammar, genealogy_schema)
puts "-"*50
DisplayFormat.print(genealogy_grammar, gannholm2)

puts "-"*50
Print.print gannholm2, { :members => {} }

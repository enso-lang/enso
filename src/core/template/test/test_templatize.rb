
require 'core/template/code/templatize_schema'
require 'core/template/code/templatize_grammar'

require 'core/schema/tools/print'

gs = Loader.load("grammar.schema")
ss = Loader.load("schema.schema")
sg = Loader.load("schema.grammar")
sg = Loader.load("schema.grammar")
puts "-"*50
class TemplatizeSchemaSchema < TemplatizeSchema
  templatize(Loader.load("schema.schema").classes["Schema"])
end
ssps = TemplatizeSchemaSchema.schema
#Print.print(ssps)
DisplayFormat.print(sg, ssps)

sspg = TemplatizeGrammar.new.templatize(sg, ss.classes["Schema"])
DisplayFormat.print(Loader.load("grammar.grammar"), sspg)

result = Parse.load_raw <<-SCHEMA, sspg, ssps, Factory.new(ssps)
  class Test
    x: [param]
  end
SCHEMA
Print.print(result)

#puts "-"*50
#class TemplatizeGrammarSchema < TemplatizeSchema
#  templatize(Loader.load("grammar.schema").classes["Grammar"])
#end
#
#gsps = TemplatizeGrammarSchema.schema
#DisplayFormat.print(sg, gsps)

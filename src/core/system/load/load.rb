
require 'core/grammar/code/parse'
require 'core/system/boot/grammar_grammar'
require 'core/system/boot/grammar_schema'
require 'core/system/boot/schema_schema'



module Loading
  class Loader

    # TODO: get rid of bootstrap models in memory

    GRAMMAR_GRAMMAR = 'grammar.grammar'
    SCHEMA_SCHEMA = 'schema.schema'
    SCHEMA_GRAMMAR = 'schema.grammar'

    def initialize
      @cache = {}
    end
    
    def load(filename)
      model, type = filename.split(/\./)
      g = load_grammar("#{type}.grammar")
      s = load_schema("#{type}.schema")
      _load(filename, g, s)
    end
        

    private

    def load_schema(filename)
      g = load_grammar(SCHEMA_GRAMMAR)
      if filename == SCHEMA_SCHEMA then
        s = SchemaSchema.schema
        _load(SCHEMA_SCHEMA, g, s)
      else
        s = load_schema(SCHEMA_SCHEMA)
        _load(filename, g, s)
      end
    end      
    

    def load_grammar(filename)
      if filename == GRAMMAR_GRAMMAR then
        s = GrammarSchema.schema
        g = GrammarGrammar.grammar
        _load(GRAMMAR_GRAMMAR, g, s)
      elsif filename == SCHEMA_GRAMMAR then
        s = GrammarSchema.schema
        g = GrammarGrammar.grammar
        _load(SCHEMA_GRAMMAR, g, s)
      else
        s = load_schema(filename)
        g = load_grammar(GRAMMAR_GRAMMAR)
        _load(filename, g, s)
      end 
    end


    def _load(filename, grammar, schema)
      model, type = filename.split(/\./)
      @cache[type] ||= {}
      if @cache[type][model] then
        return @cache[type][model]
      end
      @cache[type][model] = __load(filename, grammar, schema)
    end

    def __load(filename, grammar, schema)
      path = Dir['**/*.*'].find do |p|
        File.basename(p) == filename
      end
      CPSParser.load(path, grammar, schema)
    end

  end

end

Loader = Loading::Loader.new


if __FILE__ == $0 then
  l = Loader

  p l.load('grammar.grammar')
  p l.load('schema.grammar')
  p l.load('grammar.schema')
  p l.load('schema.schema')
  p l.load('parsetree.schema')
  p l.load('layout.schema')
  p l.load('instance.schema')
  p l.load('proto.schema')

  #p l.load_parsetree('bla.pt')
end

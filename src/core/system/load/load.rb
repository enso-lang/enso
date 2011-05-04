
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

    
    def load_schema(name)
      g = load_grammar('schema')
      if name == 'schema' then
        s = SchemaSchema.schema
        load(SCHEMA_SCHEMA, g, s)
      else
        s = load_schema('schema')
        load("#{name}.schema", g, s)
      end
    end      
    

    def load_grammar(name)
      if name == 'grammar' then
        s = GrammarSchema.schema
        g = GrammarGrammar.grammar
        load(GRAMMAR_GRAMMAR, g, s)
      elsif name == 'schema'
        s = GrammarSchema.schema
        g = GrammarGrammar.grammar
        load(SCHEMA_GRAMMAR, g, s)
      else
        s = load_schema(name)
        g = load_grammar('grammar')
        load("#{name}.grammar", g, s)
      end 
    end

    def method_missing(sym, *args, &block)
      if sym =~ /^load_(.*)$/ then
        # parser file args[0] using grammar of $1
        g = load_grammar($1)
        s = load_schema($1)
        load("#{name}.#{$1}", g, s)
      else
        super(sym, *args, &block)
      end
    end

    private

    def load(filename, grammar, schema)
      model, type = filename.split(/\./)
      @cache[type] ||= {}
      if @cache[type][model] then
        return @cache[type][model]
      end
      path = Dir['**/*.*'].find do |p|
        File.basename(p) == filename
      end
      @cache[type][model] = CPSParser.load(path, grammar, schema)
    end

  end

end

Loader = Loading::Loader.new


if __FILE__ == $0 then
  l = Loader

  p l.load_grammar('grammar')
  p l.load_grammar('schema')
  p l.load_schema('grammar')
  p l.load_schema('schema')
  p l.load_schema('parsetree')
  p l.load_schema('layout')
  p l.load_schema('constructor')

  #p l.load_parsetree('bla.pt')
end

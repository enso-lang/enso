
require 'core/system/boot/grammar_grammar'
require 'core/system/boot/grammar_schema'
require 'core/system/boot/schema_schema'

# these are here in case any of the "eval" code needs it
require 'core/grammar/code/parse'
require 'core/diff/code/merge'


module Loading
  class Loader

    # TODO: get rid of bootstrap models in memory

    GRAMMAR_GRAMMAR = 'grammar.grammar'
    SCHEMA_SCHEMA = 'schema.schema'
    SCHEMA_GRAMMAR = 'schema.grammar'
    GRAMMAR_SCHEMA = 'grammar.schema'
    
    def load(name)
      setup() if @cache.nil?
      
      return @cache[name] if @cache[name]
      @cache[name] = _load(name)
    end
    
    def loadText(type, source)
      g = load("#{type}.grammar")
      s = load("#{type}.schema")
      CPSParser.load("-", source, g, s)
    end
        
    private

    def _load(name)
      # this is very cool!
      model, type = name.split(/\./)
      g = load("#{type}.grammar")
      s = load("#{type}.schema")
      return load_with_models(name, g, s)
    end
        
    def setup
      @cache = {}
      gg = GrammarGrammar.grammar
      gs = GrammarSchema.schema
      ss = SchemaSchema.schema
      # load the real things
      gg = @cache[GRAMMAR_GRAMMAR] = load_with_models(GRAMMAR_GRAMMAR, gg, gs)
      sg = @cache[SCHEMA_GRAMMAR] = load_with_models(SCHEMA_GRAMMAR, gg, gs)
      ss = @cache[SCHEMA_SCHEMA] = load_with_models(SCHEMA_SCHEMA, sg, ss)
      gs = @cache[GRAMMAR_SCHEMA] = load_with_models(GRAMMAR_SCHEMA, sg, ss)
    end
    
    def load_with_models(name, grammar, schema)
      find_model(name) do |path|
        load_path(path, grammar, schema)
      end
    end

    def load_path(path, grammar, schema)
      header = File.open(path, &:readline)
      if header =~ /#ruby/
        puts "## building #{path}..."
        instance_eval(File.read(path))
      else
        puts "## loading #{path}..."
        CPSParser.loadFile(path, grammar, schema)
      end
    end
    
    def find_model(name) 
      path = Dir['**/*.*'].find do |p|
        File.basename(p) == name
      end
      raise "File not found #{name}" unless path
      yield path
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
  p l.load('value.schema')
  p l.load('proto.schema')

  p l.load('instance.schema')

  #p l.load_parsetree('bla.pt')
end

# library stuff
require 'core/system/library/schema'

require 'core/system/boot/grammar_grammar'
require 'core/system/boot/grammar_schema'
require 'core/system/boot/schema_schema'

# these are here in case any of the "eval" code needs it
require 'core/grammar/code/parse'
require 'core/diff/code/merge'

require 'core/system/boot/instance_schema'

module Loading
  class Loader

    # TODO: get rid of bootstrap models in memory

    GRAMMAR_GRAMMAR = 'grammar.grammar'
    SCHEMA_SCHEMA = 'schema.schema'
    SCHEMA_GRAMMAR = 'schema.grammar'
    GRAMMAR_SCHEMA = 'grammar.schema'
    INSTANCE_SCHEMA = 'instance.schema'
    
    def load(name)
      setup() if @cache.nil?
      
      return @cache[name] if @cache[name]
      @cache[name] = _load(name)
    end
    
    def loadText(type, source)
      g = load("#{type}.grammar")
      s = load("#{type}.schema")
      Parse.load(source, g, s)
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
      puts "Initializing.."

      @cache[INSTANCE_SCHEMA] = InstanceSchema.schema

      bss = @cache[SCHEMA_SCHEMA] = SchemaSchema.schema
      bgs = @cache[GRAMMAR_SCHEMA] = GrammarSchema.schema
      bgg = @cache[GRAMMAR_GRAMMAR] = GrammarGrammar.grammar
      bsg = @cache[SCHEMA_GRAMMAR] = load_with_models(SCHEMA_GRAMMAR, bgg, bgs)
      # load the real things
      ss = @cache[SCHEMA_SCHEMA] = load_with_models(SCHEMA_SCHEMA, bsg, bss)
      # now we have the schema schema, so we can fix up the pointers  
      
      # now eliminate all references to boot schema
      SchemaSchema.patch_schema_pointers(ss, ss)
      gs = @cache[GRAMMAR_SCHEMA] = load_with_models(GRAMMAR_SCHEMA, bsg, ss)
 
      # now that we have a good schema schema, load the other three, including the first two
      sg = @cache[SCHEMA_GRAMMAR] = load_with_models(SCHEMA_GRAMMAR, bgg, gs)
      gg = @cache[GRAMMAR_GRAMMAR] = load_with_models(GRAMMAR_GRAMMAR, bgg, gs)
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
        Parse.load_file(path, grammar, schema)
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
  p l.load('layout.schema')
  p l.load('value.schema')
  p l.load('proto.schema')

  p l.load('instance.schema')

  #p l.load_parsetree('bla.pt')
end

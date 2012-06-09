# library stuff
require 'core/system/library/schema'

require 'core/system/boot/meta_schema'

require 'core/grammar/parse/parse'
require 'core/schema/tools/union'
require 'core/schema/tools/rename'
require 'core/schema/tools/loadxml'

require 'core/feature/code/load'

require 'rexml/document'

class String
  def is_binary_data?
    ( self.count( "^ -~", "^\r\n" ).fdiv(self.size) > 0.3 || self.index( "\x00" ) ) unless empty?
  end
end

module Loading
  class Loader
    include REXML

    # TODO: get rid of bootstrap models in memory

    GRAMMAR_GRAMMAR = 'grammar.grammar'
    SCHEMA_SCHEMA = 'schema.schema'
    SCHEMA_GRAMMAR = 'schema.grammar'
    GRAMMAR_SCHEMA = 'grammar.schema'

    def load(name, type = nil)
      setup() if @cache.nil?
      
      return @cache[name] if @cache[name]
      load!(name, type)
    end
    
    def load!(name, type = nil)
      # ignore possibly cached model
      @cache[name] = _load(name, type)
    end

    def load_text(type, factory, source, show = false)
      g = load("#{type}.grammar")
      s = load("#{type}.schema")
      result = Parse.load_raw(source, g, s, factory, show)
      return result.finalize
    end

    def load_cache(name, obj)
      $stderr << "## caching #{name}...\n"
      @cache[name] = obj
    end

    #private

    def _load(name, type)
      # this is very cool!
      model, type = name.split(/\./) if type.nil?
      g = load("#{type}.grammar")
      s = load("#{type}.schema")
      if g.nil? or s.nil?
        f = load("#{type}.feature")
        Interpreter(BuildFeature).build(f) unless f.nil?
        g = load("#{type}.grammar")
        s = load("#{type}.schema")
      end
      return load_with_models(name, g, s)
    end

    def load_schema_xml(file, schema = nil)
      doc = Document.new(File.read("core/system/boot/#{file}"))
      if schema.nil? then
        schema = Boot::Schema.new(doc.root)
      end
      FromXML.load(schema, doc)
    end

    def build_feature(feature)
      @feature = @feature || {}
      if not @feature.has_key? feature
        f = load(feature)
        @feature[feature] = f
        Interpreter(BuildFeature).build(f) unless f.nil?
      end
    end

    def setup
      @cache = {}
      @feature = {}
      $stderr << "Initializing...\n"

      # TODO: this is not (yet) correct bootstrapping
      # it works (probably) because our bootstrap 
      # models are correct. However, if there are
      # discrepancies strange things are bound to happen.

      @cache[SCHEMA_SCHEMA] = ss = load_with_models('schema_schema.xml', nil, nil)
      @cache[SCHEMA_SCHEMA] = ss = load_with_models('schema_schema.xml', nil, ss)
      @cache[GRAMMAR_SCHEMA] = gs = load_with_models('grammar_schema.xml', nil, ss)
      @cache[GRAMMAR_GRAMMAR] = gg = load_with_models('grammar_grammar.xml', nil, gs)
      
      @cache[SCHEMA_GRAMMAR] = sg = load_with_models('schema.grammar', gg, gs)
      @cache[SCHEMA_SCHEMA] = ss = load_with_models('schema.schema', sg, ss)
      @cache[GRAMMAR_SCHEMA] = gs = load_with_models('grammar.schema', sg, ss)
      @cache[GRAMMAR_GRAMMAR] = gg = load_with_models('grammar.grammar', gg, gs)

      @cache.each do |k,v|
        model, type = k.split(/\./)
        schema = @cache["#{type}.schema"]
        patch_schema_pointers(v, schema)
      end
    end

    def patch_schema_pointers(obj, schema)
      all_classes = []
      map(obj) do |o|
        all_classes << o;
        o
      end
      all_classes.each { |o| o.instance_eval { 
        @schema_class = schema.types[@schema_class.name]
        @factory.instance_eval { @schema = schema } 
      } }
    end

    def load_with_models(name, grammar, schema, encoding = nil)
        find_model(name) do |path|
          load_path(path, grammar, schema, encoding)
        end
    end

    def load_path(path, grammar, schema, encoding = nil)
      if path =~ /\.xml$/ then
        $stderr << "## booting #{path}...\n"
        doc = Document.new(File.read(path))
        if schema.nil? then
          # this means we are loading schema_schema.xml for the first time.
          schema = Boot::Schema.new(doc.root)
          result = FromXML.load(schema, doc)
          patch_schema_pointers(result, result)
        else
          result = FromXML.load(schema, doc)
        end
      else
        begin
          header = File.open(path, &:readline)
        rescue EOFError => err
          puts "Unable to load file #{path}"
          raise err
        end
        if header =~ /#ruby/
          $stderr << "## building #{path}...\n"
          result = instance_eval(File.read(path))
        else
          $stderr << "## loading #{path}...\n"
          result = Parse.load_file(path, grammar, schema, encoding)
        end
      end
      result.factory.file_path = path
      return result
    end
    
    def find_model(name) 
      if File.exists?(name)
        yield name
      else
        path = Dir['**/*.*'].find do |p|
          File.basename(p) == name
        end
        if path.nil?
          nil
        else
          raise EOFError, "File not found #{name}" unless path
          yield path
        end
      end
    end

  end

end

Loader = Loading::Loader.new

def Load(name)
  return Loader.load(name)
end

def Load_text(type, factory, source, show = false)
  return Loader.load_text(type, factory, source, show)
end

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

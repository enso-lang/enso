# library stuff
require 'core/system/library/schema'

require 'core/system/boot/meta_schema'

require 'core/grammar/parse/parse'
require 'core/schema/tools/union'
require 'core/schema/tools/rename'
require 'core/system/load/cache'

module Load
  class LoaderClass

    # TODO: get rid of bootstrap models in memory
    GRAMMAR_GRAMMAR = 'grammar.grammar'
    SCHEMA_SCHEMA = 'schema.schema'
    SCHEMA_GRAMMAR = 'schema.grammar'
    GRAMMAR_SCHEMA = 'grammar.schema'

    def load(name, type = nil)
      setup() if @cache.nil?
      
      if @cache[name]
        @cache[name]
      else
        load!(name, type)
      end
    end
    
    def load!(name, type = nil)
      # ignore possibly cached model
      @cache[name] = _load(name, type)
    end

    def load_text(type, factory, source, show = false)
      g = load("#{type}.grammar")
      s = load("#{type}.schema")
      result = Parse.load_raw(source, g, s, factory, show)
      result.finalize
    end

    def load_cache(name, obj)
      $stderr << "## caching #{name}...\n"
      @cache[name] = obj
    end

    #private

    def _load(name, type)
      #first check if cached XML version is still valid 
      if Cache::check_dep(name)
        $stderr << "## fetching #{name}...\n"
        Cache::load_cache(name)
      else
        filename = name.split("/")[-1]
        if type.nil?
          parts = filename.split(".")
          model = parts[0]
          type = parts[1]
        end
        g = load("#{type}.grammar")
        s = load("#{type}.schema")
        res = load_with_models(name, g, s)
        #dump it back to xml
        $stderr << "## caching #{name}...\n"
        Cache::save_cache(filename, res)
        res
      end
    end

    def setup
      @cache = {}
      $stderr << "Initializing...\n"
      
      #check if XML is not out of date then just use it
      #else load XML first then reload
      @cache[SCHEMA_SCHEMA] = ss = load_with_models('schema_schema.json', nil, nil)
      @cache[GRAMMAR_SCHEMA] = gs = load_with_models('grammar_schema.json', nil, ss)
      @cache[GRAMMAR_GRAMMAR] = gg = load_with_models('grammar_grammar.json', nil, gs)
      @cache[SCHEMA_GRAMMAR] = sg = load_with_models('schema_grammar.json', nil, gs)

      @cache[SCHEMA_SCHEMA] = ss = update_xml('schema.schema')
      @cache[GRAMMAR_SCHEMA] = gs = update_xml('grammar.schema')
      @cache[GRAMMAR_GRAMMAR] = gg = update_xml('grammar.grammar')
      @cache[SCHEMA_GRAMMAR] = sg = update_xml('schema.grammar')
    end
    
    def update_xml(name)
      if Cache::check_dep(name)
        @cache[name]
      else
        parts = name.split(".")
        model = parts[0]
        type = parts[1]
        res = load_with_models(name, load("#{type}.grammar"), load("#{type}.schema"))
        patch_schema_pointers!(res, load("#{type}.schema"))
        $stderr << "## caching #{name}...\n"
        Cache::save_cache(name, res)
        res
      end
    end

    #Note: patch_schema_pointers! does not erase all traces of old schema class
    #  depending on how they were used previously
    #  Eg. computed field methods created by the factory will still point back
    #  to the expression from the old schema class because the method was already
    #  defined before getting to this point
    def patch_schema_pointers!(obj, schema)
      all_classes = []
      Schema::map(obj) do |o|
        all_classes << o;
        o
      end
      all_classes.each do |o| 
        o.instance_eval do
          @schema_class = schema.types[schema_class.name]
          @factory.instance_eval { @schema = schema } 
        end
      end
    end

    def load_with_models(name, grammar, schema, encoding = nil)
        find_model(name) do |path|
          load_path(path, grammar, schema, encoding)
        end
    end

    def load_path(path, grammar, schema, encoding = nil)
      if path.end_with?(".xml") || path.end_with?(".json") then
        if schema.nil? then
          $stderr << "## booting #{path}...\n"
          # this means we are loading schema_schema.xml for the first time.
          result = Boot::load_path(path)
          result.factory.file_path[0] = path
          #note this may be a bug?? should file_path point to XML or to original schema.schema? 
        else
          name = path.split("/")[-1].split(".")[0]
          name[name.rindex("_")] = '.'
          result = Cache::load_cache(name)
        end
      else
        begin
          header = File.open(path, &:readline)
        rescue EOFError => err
          puts "Unable to open file #{path}"
          raise err
        end
        if header == "#ruby"
          $stderr << "## building #{path}...\n"
          str = File.read(path)
          result = instance_eval(str)
          result.factory.file_path[0] = path
          a = str.split("\"").map{|x|x.split("\'")}.flatten
          fnames = a.values_at(* a.each_index.select {|i| i.odd?})
          fnames.each {|fn| result.factory.file_path << fn}
        else
          $stderr << "## loading #{path}...\n"
          result = Parse.load_file(path, grammar, schema, encoding)
        end
      end
      result
    end

    def find_model(name, &block) 
      if File.exists?(name)
        block.call name
      else
        path = Dir['**/*.*'].find do |p|
          File.basename(p) == name
        end
        if path.nil?
          nil
        else
          raise EOFError, "File not found #{name}" unless path
          block.call path
        end
      end
    end
  end
  
  # define a singleton instance 
  Loader = LoaderClass.new
  
  def self.load(name)
    Loader.load(name)
  end
  
  def self.Load_text(type, factory, source, show = false)
    Load::load_text(type, factory, source, show)
  end
end


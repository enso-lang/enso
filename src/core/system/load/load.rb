# library stuff
require 'core/system/library/schema'
require 'core/system/boot/meta_schema'
require 'core/schema/code/factory'
require 'core/grammar/parse/parse'
require 'core/schema/tools/union'
require 'core/schema/tools/rename'
require 'core/system/load/cache'
require 'core/system/utils/paths'
require 'core/system/utils/find_model'

module Load
  class LoaderClass

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

    def _load(name, type)
      type ||= name.split('.')[-1]
      #first check if cached XML version is still valid 
      if Cache::check_dep(name)
        $stderr << "## fetching #{name}...\n"
        Cache::load_cache(name, Factory::new(load("#{type}.schema")))
      else
        g = load("#{type}.grammar")
        s = load("#{type}.schema")
        res = load_with_models(name, g, s)
        #dump it back to xml
        $stderr << "## caching #{name}...\n"
        Cache::save_cache(name, res)
        res
      end
    end

    def setup
      @cache = {}
      $stderr << "Initializing...\n"
      
      # TODO: get rid of bootstrap models in memory
    
      #check if XML is not out of date then just use it
      #else load XML first then reload
      @cache['schema.schema'] = ss = load_with_models('schema_schema.json', nil, nil)
      @cache['grammar.schema'] = gs = load_with_models('grammar_schema.json', nil, ss)
      @cache['grammar.grammar'] = load_with_models('grammar_grammar.json', nil, gs)
      @cache['schema.grammar'] = load_with_models('schema_grammar.json', nil, gs)

=begin
      @cache['schema.schema'] = ss = update_xml('schema.schema')
      @cache['grammar.schema'] = gs = update_xml('grammar.schema')
      @cache['grammar.grammar'] = update_xml('grammar.grammar')
      @cache['schema.grammar'] = update_xml('schema.grammar')
=end
      Paths::Path.set_factory Factory::new(ss)  # work around for no circular references
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
          sc = schema.types[o.schema_class.name]
          define_singleton_value(:schema_class, sc)
          @factory.instance_eval { @schema = schema }
        end
      end
    end

    def load_with_models(name, grammar, schema, encoding = nil)
        FindModel::FindModel.find_model(name) do |path|
          load_path(path, grammar, schema, encoding)
        end
    end

    def load_path(path, grammar, schema, encoding = nil)
      if path.end_with?(".json") then
        if schema.nil? then
          $stderr << "## booting #{path}...\n"
          # this means we are loading schema_schema.xml for the first time.
          result = MetaSchema::load_path(path)
#          patch_schema_pointers!(result, result)
          result.factory.file_path[0] = path
          #note this may be a bug?? should file_path point to XML or to original schema.schema? 
        else
          $stderr << "## fetching #{path}...\n"
          name = path.split("/")[-1].split(".")[0].gsub("_", ".")
          type = name.split('.')[-1]
          result = Cache::load_cache(name, Factory::new(load("#{type}.schema")))
        end
      else
        begin
          header = File.open(path, &:readline)
        rescue EOFError => err
          $stderr << "Unable to open file #{path}\n"
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

  end
  
  # define a singleton instance 
  Loader = LoaderClass.new
  
  def self.load(name)
    Load::Loader.load(name)
  end
  
  def self.Load_text(type, factory, source, show = false)
    Load::load_text(type, factory, source, show)
  end
end


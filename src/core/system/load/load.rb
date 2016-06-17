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

    def _load(name, type)
      type ||= name.split('.')[-1]
      #first check if cached XML version is still valid 
      if Parse.nil? || Cache::check_dep(name)
        $stderr << "## fetching #{name}...\n"
        Cache::load_cache(name, Factory::new(load("#{type}.schema")))
      else
        g = load("#{type}.grammar")
        s = load("#{type}.schema")
        res = load_with_models(name, g, s)
        #dump it back to xml
        $stderr << "## caching #{name}...\n"
        Cache::save_cache(name, res, false)
        res
      end
    end

    def setup
      @cache = {}
      
      # TODO: get rid of bootstrap models in memory
    
      #check if XML is not out of date then just use it
      #else load XML first then reload
      @cache['schema.schema'] = ss = load_with_models('schema_schema.json', nil, nil)
      @cache['grammar.schema'] = gs = load_with_models('grammar_schema.json', nil, ss)
      @cache['grammar.grammar'] = load_with_models('grammar_grammar.json', nil, gs)
      @cache['schema.grammar'] = load_with_models('schema_grammar.json', nil, gs)

      Paths::Path.set_factory Factory::new(ss)  # work around for no circular references

      if false
	      update_json('schema.schema')
	      update_json('grammar.schema')
	      update_json('grammar.grammar')
	      update_json('schema.grammar')
	    end
    end

    def update_json(name)
      parts = name.split(".")
      model = parts[0]
      type = parts[1]
      if Cache::check_dep(name)
        patch_schema_pointers!(@cache[name], load("#{type}.schema"))
      else
        #if file has been updated, reload file using current models
        @cache[name] = load_with_models(name, load("#{type}.grammar"), load("#{type}.schema"))
        new = @cache[name]
        #now reload file with itself -- this ensures its schema information is correct
        @cache[name] = Union::Copy(Factory::new(load("#{type}.schema")), new)
        #patch schema pointers 
        #patch_schema_pointers!(@cache[name], load("#{type}.schema"))
        #save to json
        @cache[name].factory.file_path = new.factory.file_path
        Cache::save_cache(name, @cache[name], true)
      end
    end

    #Note: patch_schema_pointers! does not erase all traces of old schema class
    #  depending on how they were used previously
    #  Eg. computed field methods created by the factory will still point back
    #  to the expression from the old schema class because the method was already
    #  defined before getting to this point
    def patch_schema_pointers!(obj, schema)
      all_classes = {}
      Schema::map(obj) do |o|
        all_classes[o] = schema.types[o.schema_class.name]
        o
      end
      all_classes.each do |o, sc|
        o.instance_eval do
          define_singleton_value(:schema_class, sc)
#          @factory.instance_eval { @schema = schema }  #[JS HACK] This line does not work in JS (even though instance_eval does)
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
          # this means we are loading schema_schema.json for the first time.
          result = MetaSchema::load_path(path)
        else
          $stderr << "## fetching #{path}...\n"
          name = path.split("/")[-1].split(".")[0].gsub("_", ".")
          type = name.split('.')[-1]
          result = Cache::load_cache(name, Factory::new(load("#{type}.schema")))
        end
      elsif Parse.nil?
        $stderr << "## fetching! #{path}...\n"
        name = path.split("/")[-1]
        type = name.split('.')[-1]
        result = Cache::load_cache(name, Factory::new(load("#{type}.schema")))
      else
        $stderr << "## loading #{path}...\n"
        result = Parse.load_file(path, grammar, schema, encoding)
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

  def self.load_with_models(name, grammar, schema, encoding = nil)
    Load::Loader.load_with_models(name, grammar, schema, encoding)
  end
end

if __FILE__ == $0
  data_files = ARGV
  if data_files.nil? or data_files.size <= 0
    abort "Usage: ruby load.rb <model>"
  end
  data_files.each do |file|
    begin; Load::load(file); rescue; end
  end
end


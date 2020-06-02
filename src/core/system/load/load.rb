# library stuff
require 'core/system/library/schema'
require 'core/system/boot/meta_schema'
require 'core/schema/code/factory'
require 'core/grammar/parse/parse'
require 'core/schema/tools/union'
require 'core/system/load/cache'
require 'core/system/utils/schemapath'
require 'core/system/utils/find_model'
require 'enso'

module Load
  class LoaderClass
    def setup()
      @cache = {}
      
      # TODO: get rid of bootstrap models in memory
    
      #check if XML is not out of date then just use it
      #else load XML first then reload
      ss = boot_from_cache('schema.schema', nil)
      ss = boot_from_cache('schema.schema', ss)
      @cache['schema.schema'] = ss
      gs = boot_from_cache('grammar.schema', ss)
      @cache['grammar.schema'] = gs
      @cache['grammar.grammar'] = boot_from_cache('grammar.grammar', gs)
      @cache['schema.grammar'] = boot_from_cache('schema.grammar', gs)

      Schemapath::Path.set_factory Factory::SchemaFactory.new(ss)  # work around for no circular references

			# whether to update the four core models
      if false
	      update_json('grammar.grammar')
	      update_json('schema.grammar')
	      update_json('schema.schema')
	      update_json('grammar.schema')
	    end
    end

    # load from cache as the only option
    def boot_from_cache(model, schema)
      path = Cache::find_json(model)
      if schema.nil? then
        ##$stderr << "## booting #{path}\n"
        # this means we are loading schema_schema.json for the first time.
        result = MetaSchema::load_path(path)
      else
        #$stderr << "## fetching #{path}\n"  #if !path.include? "/boot/"
        result = Cache::load_cache(model, schema, path)
      end
    end

		# this is the main load function
		# first try the in memory cache
		# then try loading from disk
		# finally, parse the file from source
    def load(model)
      setup() if @cache.nil?
      
      result = @cache[model]
      if result.nil?
	      type = model.split('.')[1]
	      #first check if cached XML version is still valid 
	      # don't check the dependencies if we can't parse anyway
	      if Enso::System.is_javascript() || Cache::check_dep(model)
          begin
		        $stderr << ("## fetching #{model}")
		        schema = load("#{type}.schema")
		        result = Cache::load_cache(model, schema)
			    rescue Errno::ENOENT => e
			    end
				end
	      if result.nil? && !Enso::System.is_javascript()
		      $stderr << ("## parsing and caching #{model}")
	        result = parse_with_type(model, type)
		      #dump it back to xml
		      $stderr << ("## caching #{model}")
		      Cache::save_cache(model, result, false)
		      result
	      end
        @cache[model] = result
      end
      raise "Model not loaded: #{model}" if result.nil?
      result
    end
    
    def load!(model, type = nil)
      @cache.delete(model)
      # ignore possibly cached model
      @cache[model] = load(model, type)
    end

    def load_text(type, factory, source, show = false)
      g = load("#{type}.grammar")
      s = load("#{type}.schema")
      result = Parse.load_raw(source, g, s, factory, show)
      result.finalize
    end
    
    def parse_with_type(model, type)
      g = load("#{type}.grammar")
      s = load("#{type}.schema")
      res = parse_with_models(model, g, s)
    end

    def parse_with_models(model, grammar, schema, encoding = nil)
        FindModel::find_model(model) do |path|
          Parse.load_file(path, grammar, schema, encoding)
        end
    end
    
    def update_json(model)
      parts = model.split(".")
      name = parts[0]
      type = parts[1]
      if Cache::check_dep(model)
        patch_schema_pointers!(@cache[model], load("#{type}.schema"))
      else
        #if file has been updated, reload file using current models
        @cache[model] = parse_with_models(model, load("#{type}.grammar"), load("#{type}.schema"))
        other = @cache[model]
        $stderr << ("Checked!!! #{name} .... #{model}")
        #now reload file with itself -- this ensures its schema information is correct
        @cache[model] = Union::Copy(Factory::SchemaFactory.new(load("#{type}.schema")), other)
        #patch schema pointers 
        #patch_schema_pointers!(@cache[model], load("#{type}.schema"))
        #save to json
        @cache[model].factory.file_path = other.factory.file_path
        Cache::save_cache(model, @cache[model], true)
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
        end
      end
    end
  end

  
  # define a singleton instance 
  Loader = LoaderClass.new
  
  def self.load(name)
    Load::Loader.load(name)
  end

  def self.load!(name)
    Load::Loader.load!(name)
  end
  
  def self.Load_text(type, factory, source, show = false)
    Load::load_text(type, factory, source, show)
  end

end


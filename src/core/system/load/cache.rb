require 'core/schema/tools/dumpjson'
require 'core/system/utils/find_model'
require 'core/schema/code/factory'
require 'digest/sha1'
require 'enso'

module Cache

	def self.hack_prefix
	  if Enso::System.is_javascript() # HACK TO GET ELECTRON RUNNING!!!
	    "../" 
    else
			""
		end
  end
	
  def self.save_cache(name, model, full=false)
    out = find_json(name)
    res = add_metadata(name, model)
    res['model'] = Dumpjson::to_json(model, full)
    File.open(out, 'w+') do |f| 
      f.write(JSON.pretty_generate(res, allow_nan: true, max_nesting: false))
    end
  end

  # this default param is currently not supported by the Rascal compiler.
  # because it captures an earlier parameter.
  def self.load_cache(model, schema, path = find_json(model))
    factory = Factory::SchemaFactory.new(schema)
    #STDERR.puts("## loading cache for: #{model} (#{path})")
    json = Enso::System.readJSON(path)
    res = Dumpjson::from_json(factory, json['model'])
    res.factory.file_path[0] = path
    json['depends'].each {|dep| res.factory.file_path << dep['filename']}
    res
  end

  def self.check_dep(name)
    begin
      path = find_json(name)
      json = Enso::System.readJSON(path)

      #check that the source file has not changed
      #check that none of the dependencies have changed
      check_file(json) && json['depends'].all? {|e| check_file(e)}
    rescue Errno::ENOENT => e
      false
    end
  end

  def self.clean(name=nil)
    cache_path = "cache/"
    if name.nil? #clean everything
      if File.exists?("#{cache_path}")
        Dir.foreach("#{cache_path}") do |f|
          if f.end_with?(".json")
            File.delete("#{cache_path}#{f}")
          end
        end
        true
      else
        false
      end
    else
      if ['schema.schema', 'schema.grammar', 'grammar.schema', 'grammar.grammar'].include?(name)
        false
      else
        if File.exists?(find_json(name))
          File.delete(find_json(name))
          true
        else
          false
        end
      end
    end
  end

  def self.find_json(name)
    if ['schema.schema', 'schema.grammar', 'grammar.schema', 'grammar.grammar'].include?(name)
      "#{hack_prefix}core/system/boot/#{name}.json"
    else
	    cache_path = "#{hack_prefix}cache/"
      "#{cache_path}#{name}.json"
    end
  end
  
  def self.check_file(element)
    if Digest.nil?
      true
    else
	    path = element['source']
	    checksum = element['checksum']
	    begin
	      readHash(path)==checksum
	    rescue
	      false
	    end
	  end
  end

  def self.get_meta(name)
    e = {filename: name}
    begin
	    FindModel::find_model(name) do |path|
	      e['source'] = path
	      e['date'] = File.ctime(path)
	      e['checksum'] = readHash(path)
	    end
	  rescue
      e['source'] = "SYNTHETIC"
      e['date'] = Time.new
    end
    e
  end

  def self.add_metadata(name, model)
    if name==nil
      e = {filename: 'MetaData'}
    else
      e = get_meta(name)
      type = name.split('.')[-1]

      #vertical deps up the metamodel stack
      deps = []
      deps << get_meta("#{type}.grammar")

      #analyze horizontal dep
      #something to do with imports
      # STDERR.puts "METADATA #{model.factory.file_path}"
      if model.factory.file_path.size > 0
	      model.factory.file_path[1..-1].each {|fn| deps << get_meta(fn.split("/")[-1])}
	    end
      e['depends'] = deps
    end
    e
  end

  def self.readHash(path)
    hashfun = Digest::SHA1.new
    fullfilename = path
    open(fullfilename, "r") do |io|
      while (!io.eof)
        readBuf = io.readpartial(50)
        hashfun.update(readBuf)
      end
    end
    hashfun.to_s
  end

end


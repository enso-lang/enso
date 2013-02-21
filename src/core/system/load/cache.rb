
require 'core/schema/tools/dumpjson'
require 'digest/sha1'

module Cache

  def self.save_cache(name, model=Load::load(name), out=find_json(name))
    res = add_metadata(name, model)
    res['model'] = ToJSON.to_json(model, true)
    File.open(out, 'w+') do |f| 
      f.write(JSON.pretty_generate(res, allow_nan: true, max_nesting: false))
    end
  end

  def self.load_cache(name, input=find_json(name))
    type = name.split('.')[-1]
    factory = Factory::new(Load::load("#{type}.schema"))
    json = System.readJSON(input)
    res = ToJSON.from_json(factory, json['model'])
    res.factory.file_path[0] = json['source']
    json['depends'].each {|dep| res.factory.file_path << dep['filename']}
    res
  end

  def self.check_dep(name)
    begin
      path = find_json(name)
      json = System.readJSON(path)

      #check that the source file has not changed
      #check that none of the dependencies have changed
      check_file(json) && json['depends'].all? {|e| check_file(e)}
    rescue Errno::ENOENT => e
      false
    end
  end

  def self.clean(name=nil)
    if name.nil?  #clean everything
      File.delete("#{cache_path}*") if File.exists?("#{cache_path}*") 
    else
      File.delete(find_json(name)) if File.exists?(find_json(name))
    end
  end


  def self.cache_path; "core/system/load/cache/"; end
  
  def self.find_json(name)
    if ['schema.schema', 'schema.grammar', 'grammar.schema', 'grammar.grammar'].include? name
      "core/system/boot/#{name.gsub('.','_')}.json"
    else
      "#{cache_path}#{name.gsub('.','_')}.json"
    end
  end
  
  def self.check_file(element)
    path = element['source']
    checksum = element['checksum']
    begin
      readHash(path)==checksum
    rescue
      false
    end
  end
  
  def self.get_meta(name)
    e = {filename: name}
    Load::Loader.find_model(name) do |path|
      e['source'] = path
      e['date'] = File.ctime(path)
      e['checksum'] = readHash(path)
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
      deps << get_meta("#{type}.schema")
      deps << get_meta("#{type}.grammar")

      #analyze horizontal dep
      #something to do with imports
      model.factory.file_path[1..-1].each {|fn| deps << get_meta(fn.split("/")[-1])}
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


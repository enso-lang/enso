
#require 'core/system/utils/schemapath'
require 'core/system/library/schema'
require 'core/system/boot/meta_schema'
require 'json'
require 'enso'

module Dumpjson

  def self.to_json(json, do_all = false)
    if json.nil?
      nil
    else
      e = {}
      e["class"] = json.schema_class.name
      #e["_"] = json.identity
      json.schema_class.fields.each do |f|
        name = f.name
        val = json[name]
        if do_all || val
          if f.type.is_a?("Primitive") then
            e["#{name}="] = val
          else 
            if f.many then
              name = name + "#" if f.type.key
              ef = []
              if f.traversal then
                val.each do |fobj|
                  ef << to_json(fobj, do_all)
                end
              else
                val.each do |fobj|
                  ef << fixup_path(fobj)
                end
              end
              e[name] = ef if do_all || ef.size > 0
            else
              if do_all || !val.nil?
                if f.traversal then
                  e[name] = val && to_json(val, do_all)
                else
                  e[name] = val && fixup_path(val)
                end
              end
            end
          end
        end
      end
      e
    end
  end

  def self.fixup_path(obj)
    path = obj._path.to_s
    #puts "PATH #{path}"
    if path == "root"
      path = ""
    else
      path = path.slice(5,999)
    end
  end
  
  class Fixup
    def initialize(obj, field, spec)
      @obj = obj
      @field = field
      @spec = spec
    end
    
    def apply(root)
      if !@field.many
        @obj[@field.name] = MetaSchema::path_eval(@spec, root)
      else
        collection = @obj[@field.name]
        @spec.each do |path|
          collection << MetaSchema::path_eval(path, root)
        end
      end
    end
  end

  class FromJSON
    def initialize(factory)
      @factory = factory
    end
    
    def decode(json)
      @fixups = []
      res = from_json(json)
      @fixups.each do |fix|
        fix.apply(res)
      end
      res
    end
  
    def from_json(json)
      if json.nil?
        nil
      else
        obj = @factory[json['class']]
        obj.schema_class.fields.each do |f|
          if f.type.is_a?("Primitive")
            val = json["#{f.name}="]
            obj[f.name] = val if !val.nil?
          elsif !f.many
            if json[f.name].nil?
              obj[f.name] = nil
            else
              if f.traversal
                obj[f.name] = from_json(json[f.name])
              else
                @fixups << Fixup.new(obj, f, json[f.name])
              end 
            end
          else #multi-valued objects 
            fname = f.type.key ? "#{f.name}#" : f.name
            if !json[fname].nil?
	            if f.traversal
	              json[fname].each do |o|
	                obj[f.name] << from_json(o) 
	              end 
	            else
	              @fixups << Fixup.new(obj, f, json[fname])
	            end
	          end
          end
        end
        obj
      end
    end
  end
  
  def self.from_json(factory, text)
    FromJSON.new(factory).decode(text)
  end

end

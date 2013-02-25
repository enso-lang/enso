
require 'core/system/utils/paths'
require 'core/system/library/schema'
require 'json'

module Dumpjson

  def self.to_json(this, do_all = false)
    if this.nil?
      nil
    else
      e = {}
      e["class"] = this.schema_class.name
      #e["_"] = this._id
      this.schema_class.fields.each do |f|
        name = f.name
        val = this[name]
        if do_all || val
          if f.type.Primitive? then
            e["#{name}="] = val
          else 
            if f.many then
              name = name + "#" if Schema::is_keyed?(f.type)
              ef = []
              if f.traversal then
                val.each do |fobj|
                  ef << to_json(fobj, do_all)
                end
              else
                val.each do |fobj|
                  ef << fobj._path.to_s
                end
              end
              e[name] = ef if do_all || ef.length > 0
            else
              if do_all || val
                if f.traversal then
                  e[name] = val && to_json(val, do_all)
                else
                  e[name] = val && val._path.to_s
                end
              end
            end
          end
        end
      end
      e
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
        @obj[@field.name] = Paths::parse(@spec).deref(root)
      else
        collection = @obj[@field.name]
        @spec.each do |path|
          collection << Paths::parse(path).deref(root)
        end
      end
    end
  end

  class FromJSON
    def initialize(factory)
      @factory = factory
    end
    
    def parse(this)
      @fixups = []
      res = from_json(this)
      @fixups.each do |fix|
        fix.apply(res)
      end
      res
    end
  
    def make_primitive(str, type=nil)
      case type
      when 'int'
        str.to_i
      when 'str'
        str.to_s
      when 'bool'
        str.to_s.casecmp("True")==0
      when 'real'
        str.to_real
      when nil  #ie. guess
      end
    end
  
    def from_json(this)
      if this.nil?
        nil
      else
        obj = @factory[this['class']]
        obj.schema_class.fields.each do |f|
          if f.type.Primitive?
            obj[f.name] = make_primitive(this["#{f.name}="], f.type.name)
          elsif !f.many
            if this[f.name].nil?
              obj[f.name] = nil
            else
              if f.traversal
                obj[f.name] = from_json(this[f.name])
              else
                @fixups << Fixup.new(obj, f, this[f.name])
              end 
            end
          else #multi-valued objects 
            fname = Schema::is_keyed?(f.type) ? "#{f.name}#" : f.name
            if f.traversal
              this[fname].each do |o|
                obj[f.name] << from_json(o) 
              end 
            else
              @fixups << Fixup.new(obj, f, this[fname])
            end
          end
        end
        obj
      end
    end
  end
  
  def self.from_json(factory, this)
    FromJSON.new(factory).parse(this)
  end
  
  def self.to_json_string(this)
    JSON.pretty_generate(to_json(this, true))
  end

  def self.from_json_string(str)
    from_json(JSON.parse(str))
  end

end

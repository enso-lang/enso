
require 'core/system/utils/paths'
require 'json'

module ToJSON

  def self.to_json(this, do_all = false)
    return nil if this.nil?
    e = {}
    e["class"] = this.schema_class.name
    #e["_"] = this._id
    this.schema_class.fields.each do |f|
      name = f.name
      val = this[name]
      next if !(do_all || val)
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
    return e
  end

  def self.from_json(factory, this)
    fixups = {}
    res = from_json2(factory, this, fixups)
    fixup(fixups, res)
    res
  end

  def self.to_json_string(this)
    JSON.pretty_generate(to_json(this, true))
  end

  def self.from_json_string(factory, str)
    from_json(factory, JSON.parse(str))
  end

  private

  def self.make_primitive(str, type=nil)
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

  def self.from_json2(factory, this, fixups)
    return nil unless this
    obj = factory[this['class']]
    obj.schema_class.fields.each do |f|
      if f.type.Primitive?
        obj[f.name] = make_primitive(this["#{f.name}="], f.type.name)
      elsif !f.many
        if this[f.name].nil?
          obj[f.name] = nil
        else
          if f.traversal
            obj[f.name] = from_json2(factory, this[f.name], fixups)
          else
            fixups[[obj, f]] = this[f.name]
          end 
        end
      else #multi-valued objects 
        fname = Schema::is_keyed?(f.type) ? "#{f.name}#" : f.name
        if f.traversal
          this[fname].each do |o|
            obj[f.name] << from_json2(factory, o, fixups) 
          end 
        else
          fixups[[obj, f]] = this[fname]
        end
      end
    end
    obj
  end

  def self.fixup(fixups, root)
    fixups.each do |k, v|
      obj, f = k
      if !f.many
        path = v
        obj[f.name] = Paths::parse(path).deref(root)
      else
        v.each do |path|
          obj[f.name] << Paths::parse(path).deref(root)
        end
      end
    end
  end
end

if __FILE__ == $0 then
  require 'core/system/load/load'
  require 'core/diff/code/diff'
  
  schema = Loader.load('schema.schema')
  json = JSON.parse(IO.readlines("core/system/boot/schema_schema.json").join("\n"))
  ss2 = ToJSON.from_json(ManagedData::Factory.new(schema), json)
  raise "Error loading schema_schema.json!" unless Diff.diff(schema, ss2).empty?

  if !ARGV[0] then
    $stderr << "Usage: #{$0} <model>\n"
    exit!
  end

  mod = Loader.load(ARGV[0])
  jj ToJSON.to_json(mod, false)
end

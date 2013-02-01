
require 'json'

module ToJSON
  include 

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
          name = name + "#" if IsKeyed?(f.type)
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
end

if __FILE__ == $0 then
  require 'core/system/load/load'

  if !ARGV[0] then
    $stderr << "Usage: #{$0} <model>\n"
    exit!
  end

  mod = Loader.load(ARGV[0])
  jj ToJSON.to_json(mod, false)
end

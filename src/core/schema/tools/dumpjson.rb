
require 'json'

module ToJSON
  include 

  def self.to_json(this)
    return nil if this.nil?
    e = {}
    e["class"] = this.schema_class.name
    this.schema_class.fields.each do |f|
      next if !this[f.name]
      if f.type.Primitive? then
        e["#{f.name}="] = this[f.name].to_s
      else 
        name = f.name
        if f.many then
          name = name + "#" if IsKeyed?(f.type)
          ef = []
          if f.traversal then
            this[f.name].each do |fobj|
              ef << to_json(fobj)
            end
          else
            this[f.name].each do |fobj|
              ef << fobj._path.to_s
            end
          end
        else
          if f.traversal then
            ef = to_json(this[f.name])
          else
            ef = this[f.name]._path.to_s
          end
        end
        e[name] = ef
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
  jj ToJSON::to_json(mod)
end

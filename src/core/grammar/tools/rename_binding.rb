
require 'core/schema/tools/copy'

# apply a schema renaming to a grammar

class RenameBinding

  def initialize
    @memo = {}
  end

  def rename(obj, map)
    return if @memo[obj]
    @memo[obj] = true
    
    selector = obj.schema_class.name
    if respond_to?(selector) then
      send(selector, obj, map)
    else
      obj.schema_class.defined_fields.each do |f|
        next if f.type.Primitive?
        next if obj[f.name].nil?
        #next if !f.traversal
        if f.many then
          obj[f.name].each do |elt|
            rename(elt, map)
          end
          obj[f.name]._recompute_hash! if IsKeyed?(f.type)
        else
          rename(obj[f.name], map)
        end
      end
    end
  end
  
  def Create(this, map)
    old = this.name
    if map[this.name] then
      this.name = map[this.name]
    end
    rename(this.arg, old)
  end

  def Field(this, map)
    if map[this.name] then
      this.name = map[this.name]
    end
    rename(this.arg, map)
  end

  private

  def descend(map, name)
    map2 = {}
    map.each do |k, v|
      if k.is_a?(Hash) && k[name] then
        map2[k[name]] = v
      else
        map2[k] = v
      end
    end
    return map2
  end
end

def rename_binding!(grammar, map)
  RenameBinding.new.rename(grammar, map)
end

def rename_binding(grammar, map)
  obj = Clone(grammar)
  rename_binding!(obj, map)
  obj
end



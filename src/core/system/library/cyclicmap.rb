

class Dispatch
  def recurse(obj, *args)
    #puts "RENDER #{obj} #{arg}"
    raise "**UNKNOWN #{obj.class} #{obj}" if !obj.schema_class.name
    return send(obj.schema_class.name, obj, *args)
  end
end

class MemoBase
  def initialize
    @memo = {}
  end

  def self.run(*args)
    self.new().recurse(*args)
  end

  def recurse(obj, *args)
    r = @memo[obj]
    return r if r
    @memo[obj] = send(obj.schema_class.name, obj, *args)
  end

end


class CyclicCollectShy < MemoBase
  def self.run(obj)
    coll = self.new
    accu = []
    coll.recurse(obj, accu)
    return accu
  end

  def recurse(obj, accu)
    if @memo[obj] then
      return
    end
    msg = obj.schema_class.name
    @memo[obj] = true
    if respond_to?(msg) then
      send(msg, obj, accu)
    else
      send(:_, obj, accu)
    end
  end
  
  def _(this, accu)
    this.schema_class.fields.each do |f|
      v = this[f.name]
      if v && v.respond_to?(:schema_class) then
        recurse(this[f.name], accu)
      elsif v && f.many then
        v.each do |elt|
          recurse(elt, accu) if elt && elt.respond_to?(:schema_class)
        end
      end
    end
  end
end


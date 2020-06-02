
class FoldModel
  def initialize(fact)
    @fact = fact
    @memo = {}
  end

  def fold(obj)
    return nil if obj.nil?
    if @memo[obj] then
      return @memo[obj]
    end
    cls = lookup_class(obj, obj.schema_class) 
    @memo[obj] = trg = cls.new
    # for type lift to work, this should be cls.fields
    update_fields(obj, trg, obj.schema_class.fields)
    return trg
  end

  def update_fields(obj, trg, fields)
    fields.each do |f|
      if f.type.is_a?("Primitive") then
        update_prim(obj, trg, f)
      else
        update_ref(obj, trg, f)
      end
    end
  end

  def update_prim(obj, trg, f)
    x = obj[f.name]
    set!(trg, f, x)
  end

  def update_ref(obj, trg, f)
    if f.many then
      update_many(obj, trg, f)
    else
      update_single(obj, trg, f)
    end
  end

  def update_many(obj, trg, f)
    coll = []
    obj[f.name].each do |x|
      other = fold(x)
      coll << other
      update_inverse(obj, trg, f, other)
    end
    set!(trg, f, coll)
  end

  def update_single(obj, trg, f)
    other = fold(obj[f.name])
    set!(trg, f, other)
    update_inverse(obj, trg, f, other)
  end

  def update_inverse(obj, trg, f, other)
    if f.inverse then
      if f.inverse.many && Schema::is_keyed?(f.type) then
        init_if_needed(other, f.inverse, {})
        get(other, f.inverse)[Schema::object_key(obj)] = trg
      elsif f.inverse.many then
        # TODO: this has the same problem as in factory;
        # should be done in finalize.
        init_if_needed(other, f.inverse, [])
        get(other, f.inverse) << trg
      else
        set!(other, f.inverse, trg)
      end
    end
  end

  def set!(trg, f, value)
    trg.instance_variable_set(ivar(f), value)
  end

  def get(trg, f)
    trg.instance_variable_get(ivar(f))
  end

  def init_if_needed(trg, f, value)
    return if trg.instance_variable_defined?(ivar(f))
    trg.instance_variable_set(ivar(f), value)
  end

  def ivar(f)
    "@#{f.name}"
  end
end

class FFold < FoldModel
  def lookup_class(obj, scls)
    @fact.lookup(scls, Object)
  end
end

class MFold < FoldModel
  def lookup_class(obj, scls)
    @fact.const_get(obj.schema_class.name)
  end
end
  

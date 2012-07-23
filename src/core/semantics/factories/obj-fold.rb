
class Fold
  def initialize(fact)
    @fact = fact
    @memo = {}
  end

  def fold(obj)
    return nil if obj.nil?
    if @memo[obj] then
      return @memo[obj]
    end
    cls = lookup_class(obj) 
    arity = cls.instance_method(:initialize).arity
    args = [nil] * arity
    @memo[obj] = trg = cls.new(*args)
    update_fields(obj, trg, obj.instance_variables)
    return trg
  end

  def is_prim?(value)
    return value.is_a?(String) || value.is_a?(Numeric) ||
      value.is_a?(TrueClass) || value.is_a?(FalseClass) ||
      value.is_a?(Symbol)
  end
    

  def update_fields(obj, trg, ivars)
    ivars.each do |ivar|
      x = obj.instance_variable_get(ivar)
      if is_prim?(x) then
        update_prim(trg, ivar, x)
      else
        update_ref(trg, ivar, x)
      end
    end
  end

  def update_prim(trg, ivar, x)
    trg.instance_variable_set(ivar, x)
  end

  def is_many?(value)
    value.is_a?(Array) || value.is_a?(Hash)
  end

  def update_ref(trg, ivar, x)
    if is_many?(x) then
      update_many(trg, ivar, x)
    else
      update_single(trg, ivar, x)
    end
  end

  def update_many(trg, ivar, x)
    if x.is_a?(Array) then
      trg.instance_variable_set(ivar, x.map { |x| fold(x) })
    elsif x.is_a?(Hash) then
      h = {}
      x.each do |k, v|
        h[k] = fold(v)
      end
      trg.instance_variable_set(ivar, h)
    else
      raise "Error: only array and hash are supported"
    end
  end

  def update_single(trg, ivar, x)
    trg.instance_variable_set(ivar, fold(x))
  end
end

class FFold < Fold
  def lookup_class(obj)
    @fact.lookup(obj.class, obj.class)
  end
end

class MFold < Fold
  def lookup_class(obj)
    @fact.const_get(obj.schema_class.name)
  end
end
  


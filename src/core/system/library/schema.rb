
# gets the primitive-valued key of a class, if there is one
def ClassKey(klass)
  klass.fields.find { |f| f.key && f.type.Primitive? }
end

def IsKeyed?(klass)
  not klass.Primitive? and not ClassKey(klass).nil?
end

# lookup a dotted name relative to a base object
def Lookup(obj, path)
  result = Lookup1(obj, path.split("."))
  raise "Could not find path '#{path}'" if !result
  return result
end

def Lookup1(obj, path)
  return obj if path.length == 0
  field = obj.schema_class.fields.find(&:traversal)
  return Lookup1(obj[field.name][path[0]], path[1..-1])
end

def generate_name_map(obj)
  gen_nm_helper(obj, "")
end
def gen_nm_helper(obj, path)
  res = {obj => path}
  delim = path.empty? ? "" : "."  # first item does not have delimiter
  obj.schema_class.fields.each do |f|
    #TODO: Naming system (based on library/schema.lookup) only supports many fields
    next unless f.traversal and f.many

    obj[f.name].keys.each do |k|
      res.merge!(gen_nm_helper(obj[f.name][k], path + delim + k.to_s))
    end
  end
  return res
end

def Subclass?(a, b)
  return false if a.nil? || b.nil?
  return true if a.name == if b.is_a?(String) then b else b.name end
  a.supers.detect do |sup|
    Subclass?(sup, b)
  end
end

def ClassMinimum(a, b)
  return a if b.nil?
  return b if a.nil?
  if Subclass?(a, b)
    return a
  elsif Subclass?(b, a)
    return b
  else
    return nil
  end
end

  

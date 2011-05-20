
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

# get the path of an object relative to a base object
# inverse of Lookup, ie obj=Lookup(baseobj, GetPath(obj, baseobj))
def GetPath(obj, baseobj)
  return "" if baseobj == obj
  field = obj.schema_class.fields.find(&:traversal)
  key = baseobj[field.name]
  return key.to_s+"."+GetPath(obj, baseobj[key])
end

def Subclass?(a, b)
  return false if a.nil? || b.nil?
  return true if a.name == b.name
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

  

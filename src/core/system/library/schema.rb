
# gets the primitive-valued key of a class, if there is one
def ClassKey(klass)
  klass.fields.find { |f| f.key && f.type.Primitive? }
end

# lookup a dotted name relative to a base object
def Lookup1(obj, path)
  return obj if path.length == 0
  field = obj.schema_class.fields.find(&:traversal)
  return Lookup1(obj[field.name][path[0]], path[1..-1])
end

def Lookup(obj, path)
  result = Lookup1(obj, path.split("."))
  raise "Could not find path '#{path}'" if !result
  return result
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


  

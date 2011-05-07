
# gets the primitive-valued key of a class, if there is one
def ClassKey(klass)
  klass.fields.find { |f| f.key && f.type.Primitive? }
end

# gets the relationship key of a class, if there is one
def ClassKeyRel(klass)
  klass.fields.find { |f| f.key && !f.type.Primitive? }
end

module LookupMod
class Lookup 
  @@lookup_paths = {}

  def self.subtypes(klass)
    types = [klass]
    klass.subtypes.each do |sub|
      types += subtypes(sub)
    end
    return types
  end

  def self.find_keyed_rel(subs, seen)
    rel = nil
    subs.each do |klass|
      arel = klass.fields.find { |f| f.many && !seen.include?(f.type) && ClassKey(f.type) }
      raise "Ambiguous lookup in '#{rel.name}' and '#{arel.name}'" if rel && arel
      rel = rel || arel
    end
    #puts "FIND #{subs} #{seen} #{rel}"
    return rel
  end

  def self.find_paths(klass, seen)
    subs = subtypes(klass)
    seen += subs
    rel = find_keyed_rel(subs, seen)
    if rel
      return [rel.name] + self.find_paths(rel.type, seen)
    else
      return []
    end
  end

  def self.get_path(klass)
    path = @@lookup_paths[klass]
    if !path
      path = find_paths(klass, [])
      #puts "FIND #{klass} #{path}"
      @@lookup_paths[klass] = path
    end
    return path
  end
  
  def self.lookup(obj, names)
    path = get_path(obj.schema_class)
    #puts "#{obj} #{names} [#{path}]"
    raise "Can't lookup if there are no keyed fields" if path == []
  
    names.split(".").zip(path).each do |value, field|
      raise "Reference '#{names}' is longer than #{path}" if !field
      obj = obj[field][value]
      raise "Could not find #{field}['#{value}'] for #{obj}" if obj.nil?
    end
    return obj
  end
end
end

# get the lookup path, as a list of fields, for a class
def SchemaPaths(klass)
  LookupMod::Lookup.get_path(klass)
end

# lookup a dotted name relative to a base object
def Lookup(obj, path)
  LookupMod::Lookup.lookup(obj, path)
end

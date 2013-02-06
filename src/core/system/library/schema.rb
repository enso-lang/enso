module Schema
  # gets the primitive-valued key of a class, if there is one
  def self.class_key(klass)
    klass.fields.find { |f| f.key && f.type.Primitive? }
  end
  
  def self.object_key(obj)
    obj[self.class_key(obj.schema_class).name]
  end
  
  def self.is_keyed?(klass)
    not klass.Primitive? and not self.class_key(klass).nil?
  end
  
  #run DFS on obj's parent hierarchy and return first non-nil result
  #similar to find() from Ruby's Enumerable API
  def self.lookup(obj, &block)
    res = block.call(obj)
    if res
      res
    elsif obj.supers.empty?
      nil
    else
      obj.supers.find_first do |o|
        self.lookup(o, &block)
      end
    end
  end
  
  def self.subclass?(a, b)
    if a.nil? || b.nil?
      false
    elsif a.name == if b.is_a?(String) then b else b.name end
      true
    else 
      a.supers.any? do |sup|
        self.subclass?(sup, b)
      end
    end
  end
  
  def self.class_minimum(a, b)
    if b.nil?
      a 
    elsif a.nil?
      b
    elsif self.subclass?(a, b)
      a
    elsif self.subclass?(b, a)
      b
    else
      nil
    end
  end
  
  def self.map(obj, &block)
    if obj.nil?
      nil
    else
      res = block.call(obj)
      obj.schema_class.fields.each do |f|
        if f.traversal and !f.type.Primitive?
          if !f.many
            map(obj[f.name], &block)
          else
            res[f.name].keys.each do |k|
              map(obj[f.name][k], &block)
            end
          end
        end
      end
      res
    end
  end
end



# FooDelta
#   FooModify pos? foo fields  
#   FooDelete pos?
#   FooRef

class Match
  def initialize(base)
    @left_to_right = {}
    @right_to_left = {}
  end
  
  def match(type, a, b)
    return self.prim(type, a, b) if type.Primitive?
    return @factory[type.name + "Delete"] if b.nil?
    #puts "#{a} === #{b}"
    a = identify.right_to_left[b] if !a
    b = identify.left_to_right[a] if !b
    min = ClassMinimum(a.schema_class, b.schema_class)
    klass = type.schema.classes[min.name]
    #puts "KLASS #{klass}"
    nil if @memo[[a, b]]
    @memo[[a, b]] = true
    result = nil
    klass.fields.each do |field|
      asub = a[field.name]
      bsub = b[field.name]
      if !field.many
        result = self.bind(result, field, match(asub, bsub))
      els # TODO: could be an option to identify ordered fields???
        asub.outer_join(bsub) do |d1, d2, k|
          change = match(asub, bsub)
          change.pos = k
          result = self.bind(result, field, change)
        end
      end
    end
    if result
      # have to go back and patch up and identifications
    end
    
    return result
  end

  def prim(type, a, b)
    return nil if a == b
    return @factory[type.name + "Delete"] if b.nil?
    r = @factory[type.name + "Modify"]
    r.value = b
    return r
  end
  
  def bind(result, field, v)
    if v
      result = @factory[klass.name + "Modify"] if !result
      if !field.many
        result[field.name] = v
      else
        result[field.name] << v
      end
    end
    return result
  end
end

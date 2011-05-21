require 'core/system/load/load'
require 'core/grammar/code/layout'

=begin

Deep equality based on object tree structure and primitive values

=end

class Equals 

  def Equals.equals (o1, o2)
    Equals.new.eq(o1, o2)
  end

  def is_primitive_value(o)
    if o.is_a?(Integer) 
      return true
    elsif o.is_a?(String) 
      return true
    elsif o.is_a?(TrueClass) 
      return true
    elsif o.is_a?(FalseClass)
      return true
    else
      return false
    end
  end

  def eq (o1, o2)
    # the irritating fake polymorphism function
    if o1.is_a? ManyIndexedField and o2.is_a? ManyIndexedField
      return eq_ManyIndexedField(o1, o2)
    elsif o1.is_a? ManyField and o2.is_a? ManyField
      return eq_ManyField(o1, o2)
    elsif o1.schema_class.Primitive? and o2.schema_class.Primitive?
      return eq_Primitive(o1, o2)
    elsif o1.is_a? CheckedObject and o2.is_a? CheckedObject
      return eq_Klass(o1, o2)
    else # probably because o1 and o2 have different types
      return false
    end
  end

  def eq_Klass(o1, o2)
    #verify that they are the same type
    schema_class = o1.schema_class
    return false unless o2.schema_class == schema_class

    #iterate over fields
    schema_class.fields.each do |f|
      next unless f.traversal
      return false unless eq(o1[f.name], o2[f.name])
    end
    
    return true
  end

  def eq_Primitive(o1, o2)
    o1 == o2
  end

  def eq_ManyField(o1, o2)
    return false if o1.length != o2.length
    for i in 0..o1.length-1
      return false unless eq(o1[i], o2[i])
    end
    return true
  end

  def eq_ManyIndexedField(o1, o2)
    puts "in index"
    keys = o1.keys
    return false unless o2.keys == keys
    #go thru key set to make sure everything is equal
    keys.each do |k|
      return false unless eq(o1[k], o2[k])
    end
    return true
  end

end

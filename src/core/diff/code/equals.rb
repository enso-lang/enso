
=begin

Base type for equal strategies.

All subclasses must implement the following functions:
- Eq(o1, o2)
- Eq(o1, o2, match)

#TODO: Currently there is only one equals stratgy based on shallow equivalence!
=end

class Equals 
  
  def eq (o1, o2)
    #select appropriate schema based on schema_class of o1
    #assumption is that o1 and o2 are the same
    meta_schema_class = o1.schema_class.schema_class
    send("eq_"+meta_schema_class.name(), o1, o2)
  end

  def eq_deep (o1, o2, matches)
    # "deep" equality by checking that all non primitive fields 
    #point to matching objects

    schema_class = o1.schema_class

    # check if these two are of the same type
    #in most places this check would have taken place before this call is made
    if o2.schema_class != schema_class
      return false
    end

    # iterate over all fields to verify equivalence
    schema_class.fields.each do |f|
      if f.type.Primitive?
        if o1.method(f.name).call != o2.method(f.name).call 
          return false
        end
      else
        if f.type.many?
          l1 = o1.method_added(f.name).call
          l2 = o2.method_added(f.name).call
          if l1.map{|x| matches[x]} != l2
            return false
          end
        else
          if matches[o1.method_added(f.name).call] != o2.method_added(f.name).call
            return false
          end 
        end
      end
    end

    # passed every test
    return true
  end

  def eq_Klass (o1, o2)
    # check if two objects that are klasses are shallow-equivalent
    #ie. all fields of primitive types must contain the same result
    #and of course the primitive types match
  
    schema_class = o1.schema_class
  
    # check if these two are of the same type
    #in most places this check would have taken place before this call is made
    if o2.schema_class != schema_class
      return false
    end
  
    # iterate over primitive fields of the type to verify equivalence
    schema_class.fields.each do |f|
      if f.type.Primitive?
        if o1.method(f.name).call != o2.method(f.name).call 
          return false
        end
      end
    end
  
    # passed every test
    return true
  end
  
  def eq_Primitive (o1, o2)
    o1.name == o2.name
  end

end


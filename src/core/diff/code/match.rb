
=begin

Base type for match strategies.

All subclasses must implement the following functions:
- match(o1, o2) : { o1 => o2 }

#result of a match is a set of pairs of classes conforming to the specified schema
# each pair of schema classes is a match between the two objects
# schema classes includes non-type things like fields
# but does not include schema class level attributes like "many" and "super-class"
# schema classes are refered to by their paths

#TODO: Currently there is only one equals stratgy based on shallow equivalence!
=end

class Match
  
  def initialize(equals)
    @equals = equals
  end 

  def eq(o1, o2)
    @equals.eq(o1,o2)
  end
  
<<<<<<< HEAD
  def match(o1, o2)

    if eq(o1, o2)
      # add current match to results
      res = { o1 => o2 }
      # add results of matching non-primitive fields
      o1.schema_class.fields.each do |f|
        if not f.Primitive?
          if f.many
            res.merge!(match_ordered_list(o1.send(f.name), o2.send(f.name)))
          else
            res << match(o1.send(f.name), o2.send(f.name))
          end
=======
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
>>>>>>> 0c06ce259b5ee0176c29ff180cdeb8b70d650531
        end
      end
    else
      #o1 and o2 are not matched, so by this tree algo no further matching is possible
    end

    return res
  end
  
  def match_ordered_list (l1, l2)
    # simple lcm on l1 and l2
    # only match two points if they are shallow-equivalent
    
    #    if o1 and o2 are not both lists of the same type
    #       return {}
    #    end

    #figure out lcm matches by index
    lcm_matches = lcm(l1, l2, 0, 0, {}, lambda{|x,y| eq(x, y)})

    #assign object matches based on index matches
    res = {}
    lcm_matches.keys.each do |i1|
      i2 = lcm_matches[i1]
      res[l1[i1]] = l2[i2]
    end

    return res
  end

  def lcm (l1, l2, i1, i2, memo, eq)
    key = i1*l2.length()+i2
    if not memo[key].nil?
      return memo[key]
    end
    if i1<l1.length and i2<l2.length
      if eq.call(l1[i1], l2[i2])
        res = lcm(l1, l2, i1+1, i2+1, memo, eq)
        res[i1] = i2
      else
        r1 = lcm(l1, l2, i1+1, i2, memo, eq) 
        r2 = lcm(l1, l2, i1, i2+1, memo, eq)
        if (r2.length > r1.length)  
          return r2
        else 
          return r1 
        end
      end
    else 
      res = {}  # one side is already empty
    end
    memo[key] = res
    return res
  end
  
  def match_keyed_list (o1, o2)
  end

end

=begin

Check if two delta objects conflict. 
Conflict is defined operationally as "for some x, d1(d2(x)) != d2(d1(x))" (commutativity)

This definition does not guarantee or require that the result of one or both 
transformations are logically correct
This also does not protect against 'semantic interference', eg adding the same 
item to a list twice (and hence causing a bug)

Conflicts occur if:
- Same single field in an object is assigned two changes d1, d2 where
  - d1.changetype != d2.changetype *
  - (changetype = ins) and (not eq(d1, d2))
  - (changetype = mod) and field is primitive and d1 != d2
  - (changetype = mod) and field is non-primitive, and conflict(f) for some f in d.field
- Same list field in an object is assigned two changes d1, d2 where
  - (d1.pos == d2.pos) and (d1=del and d2=mod, and vice versa)
  - (d1.pos == d2.pos) and changetype = insert and (not eq(d1, d2)) *
  - (d1.pos == d2.pos) and changetype = mod and conflict(f) for some f in d.field

* this is slightly stricter than it needs to be, eg  
  inserting [1, 2] and [1, 2] to the same position will fail because not eq(1,2)
  this is subject to interpretation and may be changed later

Assumptions:
- Objects must conform to the same delta schema

=end

class Conflict

  # given two delta objects, return a set of pairs of conflicting deltas
  # one delta can occur in more than one pair
  def self.conflict(d1, d2)
    ct1 = DeltaTransform.getChangeType(d1)
    ct2 = DeltaTransform.getChangeType(d2)

    if not DeltaTransform.isManyChange?(d1) # is single-valued
      return [[d1, d2]] if ct1 != ct2

      #inserts
      if ct1 == DeltaTransform.insert
        return [[d1, d2]] if not Equals.equals(d1, d2)

      #modifys
      elsif ct1 == DeltaTransform.modify
        if DeltaTransform.isPrimitive?(d1)
          return [[d1, d2]] if d1 != d2
        else
          return conflict_Klass(d1, d2)
        end
      end
    else # is a delta to a list field
      if not d1.pos == d2.pos 
        return [] 
      end

      #del vs mod
      return [[d1, d2]] if ((ct1==DeltaTransform.modify and ct2==DeltaTransform.delete) or (ct1==DeltaTransform.delete and ct2==DeltaTransform.modify))

      #inserts
      if ct1==DeltaTransform.insert and ct2==DeltaTransform.insert
        if DeltaTransform.isKeyedMany?(d1)
          return [[d1,d2]] if not Equals.equals(d1, d2)
        else
          return [[d1,d2]]
        end

      #mods
      elsif ct1==DeltaTransform.modify and ct2==DeltaTransform.modify
        return conflict_Klass(o1, o2)
      end
    end
    return []
  end

  
  private

  # o1 and o2 are already checked not to conflict by themselves
  #this function checks if a conflict occur in their fields
  def self.conflict_Klass(o1, o2)
    res = []
    DeltaTransform.getObjectBase(o1).fields.each do |f|
      next if o1[f.name].nil? or o2[f.name].nil?

      if not f.many
        res += conflict(o1[f.name], o2[f.name])
      else #many valued
        o1[f.name].each do |f1|
          o2[f.name].each do |f2|
            res += conflict(f1, f2)
          end
        end
      end      
    end
    return res
  end
end

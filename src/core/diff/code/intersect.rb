=begin

Find all sub-deltas that are applied to the same place
For classes, consider only inserts and deletes of entire classes
For primitives, consider any change
For lists, consider changes to the same position that are:
  - two modifies
  - a modify and a delete, or
  - two sets of insertions.
Intersections need to be constructed as a set of pairs of lists, not just a
set of pairs, as sorted lists can have multiple insertions into a single pos.

All intersections that are not equivalent are *necessarily* conflicts.

Assumptions:
- Deltas are on the same base
- Objects must conform to the same delta schema

=end

class Intersect

  # return a set of pairs of delta lists that intersect with each other
  def self.intersect(d1, d2)
    res = []

    # if either is not an modify then no need to recurse
    if !DeltaTransform.isModifyChange?(d1) or !DeltaTransform.isModifyChange?(d2)
      return [[[d1],[d2]]]
    end 

    DeltaTransform.getObjectBase(d1).fields.each do |f|
      f1 = d1[f.name]
      f2 = d2[f.name]
      next if f1.nil? or f2.nil?

      if not f.many
        if DeltaTransform.isPrimitive?(f1)	#note that f.type is always non-primitive!
          res << [[f1], [f2]]
        else 
          res << intersect(f1, f2)
        end

      else #many valued -- this is the complex case
        m1 = DeltaTransform.Many2Map(f1)
        m2 = DeltaTransform.Many2Map(f2)

        m1.keys.each do |k|
          next if not m2.has_key?(k)

          d1ins = m1[k].select{|x| DeltaTransform.isInsertChange?(x)}
          d2ins = m2[k].select{|x| DeltaTransform.isInsertChange?(x)}
          d1del = m1[k].find {|x| DeltaTransform.isDeleteChange?(x)}
          d2del = m2[k].find {|x| DeltaTransform.isDeleteChange?(x)}
          d1mod = m1[k].find {|x| DeltaTransform.isModifyChange?(x)}
          d2mod = m2[k].find {|x| DeltaTransform.isModifyChange?(x)}

          if !d1mod.nil? and !d2mod.nil?
            res.merge!(intersect(d1mod, d2mod))
          elsif !d1mod.nil? and !d2del.nil?
            res << [[d1mod], [d2del]]
          elsif !d1del.nil? and !d2mod.nil?
            res << [[d1del], [d2mod]]
          end

          if !d1ins.empty? and !d2ins.empty?
            res << [d1ins, d2ins]	#this is the reason we need pairs of lists
          end

        end
      end
    end

    return res
  end

  # given an intersection, get all objects in either version 0 or 1 that are found in that in
  def self.getFrom(intersection, i)
    res = (intersection.map {|p| p[i]}).flat_map {|i| i}
    return res
  end

  # remove from d1 all deltas that overlap with d2  
  def self.subtract(d1, d2)
    intersect = intersect(d1, d2)
    deltas = getFrom(intersect, 0)
    return remove_deltas(d1, deltas)
  end

  # remove from the delta object d1 all sub-deltas found in a list of deltas 
  def self.remove_deltas(d1, deltas)
    return replace_deltas(d1, Hash[*deltas.map{|d| [d, nil]}.flat_map{|i| i}])
  end

  # apply to d1 a map from delta objects to Maybe delta objects
  def self.replace_deltas(d1, deltamap) 
    return nil if d1.nil?
    return deltamap[d1] if deltamap.has_key? d1
    return d1 unless DeltaTransform.isModifyChange?(d1)
    d1.schema_class.all_fields.each do |f|
      next if f.type.Primitive?
      next if d1[f.name].nil?
      if not f.many
        d1[f.name] = replace_deltas(d1[f.name], deltamap) 
      else
        d1[f.name].keys.each do |k|
          s = replace_deltas(d1[f.name][k], deltamap)
          if s.nil?
            d1[f.name].delete(d1[f.name][k])
          else
            d1[f.name][k] = s
          end
        end
      end
    end
    return d1
  end

end



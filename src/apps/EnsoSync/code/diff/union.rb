
require 'core/diff/code/intersect'
require 'core/diff/code/conflicts'
require 'core/schema/tools/equals'

class Union

  # union takes two deltas and combine them
  def self.union(d1, d2, factory, resolver=lambda{|c|Conflicts.resolve(c)})

    # if either is nil just return the other
    return d1 if d2.nil?
    return d2 if d1.nil?

    # if either is not an modify then no need to recurse
    if !DeltaTransform.isModifyChange?(d1) or !DeltaTransform.isModifyChange?(d2)
      if Equals.equals(d1,d2)
        return d1
      else
        return resolver.call([d1,d2])
      end
    end

    res = factory[d1.schema_class.name]
    DeltaTransform.getObjectBase(d1).fields.each do |f|
      f1 = d1[f.name]
      f2 = d2[f.name]

      if f1.nil? and not f2.nil?
        res[f.name] = f2
        next
      elsif f2.nil? and not f1.nil?
        res[f.name] = f1
        next
      elsif f1.nil? and f2.nil?
        res[f.name] = nil
        next
      end

      if not f.many
        if DeltaTransform.isPrimitive?(f1)	#note that f.type is always non-primitive!
          res[f.name] = f1
        else
          res[f.name] = union(f1, f2, factory, resolver)
        end

      else #many valued -- this is the complex case
        m1 = DeltaTransform.Many2Map(f1)
        m2 = DeltaTransform.Many2Map(f2)

        m1.keys.each do |k|
          next if m2.has_key?(k)
          m1[k].each {|d| res[f.name]<<d}
        end

        m2.keys.each do |k|
          next if m1.has_key?(k)
          m2[k].each {|d| res[f.name]<<d}
        end

        m1.keys.each do |k|
          next if not m2.has_key?(k)

          d1ins = m1[k].select{|x| DeltaTransform.isInsertChange?(x)}
          d2ins = m2[k].select{|x| DeltaTransform.isInsertChange?(x)}
          d1del = m1[k].find {|x| DeltaTransform.isDeleteChange?(x)}
          d2del = m2[k].find {|x| DeltaTransform.isDeleteChange?(x)}
          d1mod = m1[k].find {|x| DeltaTransform.isModifyChange?(x)}
          d2mod = m2[k].find {|x| DeltaTransform.isModifyChange?(x)}

          if !d1ins.empty? and !d2ins.empty?
            for i in 0..[d1ins.size,d2ins.size].max-1
              if i>=d1ins.size
                res[f.name] << d2ins[i]
              elsif i>=d2ins.size
                res[f.name] << d1ins[i]
              else
                res[f.name] << union(d1ins[i], d2ins[i], factory, resolver)
              end
            end
          end

          if !d1mod.nil? and !d2mod.nil?
            res[f.name] << union(d1mod, d2mod, factory, resolver)
          elsif !d1mod.nil? and !d2del.nil?
            res[f.name] << union(d1mod, d2del, factory, resolver)
          elsif !d1del.nil? and !d2mod.nil?
            res[f.name] << union(d1del, d2mod, factory, resolver)
          end

        end
      end
    end

    return res

  end

end
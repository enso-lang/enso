=begin

Apply a diff result conforming to delta schema as a patch script on an object

=end

require 'core/system/library/schema'

class Patch

  def self.patch(o, delta)
    return Patch.new.patch(o, delta)
  end

  def patch(o, delta)
    @old_name_map = generate_name_map(o)
    res = patch_obj(o, delta, o.factory)
    @new_name_map = generate_name_map(res)
    patch_refs!(res)
    return res
  end

  
  #############################################################################
  #start of private section  
  private
  #############################################################################
  
  def patch_obj(o, deltas, factory)
    # accepts an object o conforming to schema
    # and deltas conforming to delta-schema
    # to produce an output o' conforming to schema

    if DeltaTransform.isPrimitive?(deltas)
      #if this is a primitive object apply the changes directly
      return DeltaTransform.getValue(deltas)
    elsif DeltaTransform.isRef?(deltas)
      newo = factory[deltas.type]   #at this pt we are not sure which type to create due to subtyping
      @old_name_map[newo] = deltas.path
      return newo
    else
      # apply changes to each of its fields
      schema_class = o.schema_class
      res = factory[schema_class.name]

      schema_class.fields.each do |f|
        #get field value 
        d = deltas[f.name]
        if d.nil? #field is nil means it was not changed
          res[f.name] = o[f.name]
          next
        end
        if not f.many
          res[f.name] = patch_single(o, f.name, d, factory)
        else #many-valued field
          if IsKeyed?(f.type)
            patch_keyedlist(o, f.name, d, factory).each {|x|res[f.name]<<x}
          else
            patch_orderedlist(o, f.name, d, factory).each {|x|res[f.name]<<x}
          end 
        end
      end

      return res
    end
  end

  # create a new object based on delta
  def add_obj(delta, factory)

    if DeltaTransform.isPrimitive?(delta)
      #do nothing for now
      return DeltaTransform.getValue(delta)
    else 
      classname = DeltaTransform.getObjectName(delta)
      #fill in fields
      obj = factory[classname]
      obj.schema_class.fields.each do |f|
        next if !f.type.Primitive? and !f.traversal
        next if delta[f.name].nil?
        
        if not f.many
          obj[f.name] = add_obj(delta[f.name], factory)
        else
          obj[f.name].clear()
          delta[f.name].each do |x|
            obj[f.name] << add_obj(x, factory)
          end
        end
      end
    end

    return obj
  end

  def patch_single(o, fname, delta, factory)
    #check which type of change this was
    if DeltaTransform.isInsertChange?(delta)
      return patch_obj(o[fname], delta, factory)
    elsif DeltaTransform.isDeleteChange?(delta)
      return nil
    elsif DeltaTransform.isModifyChange?(delta)
      return patch_obj(o[fname], delta, factory)
    elsif DeltaTransform.isClearChange?(delta)
      #do nothing
      return nil
    end
  end

  def patch_orderedlist(o, fname, deltas, factory)
    res = []
    ladds = {}
    ldels = {}
    lmods = {}
    max_pos = -1
    deltas.each do |df|
      pos = df.pos
      if DeltaTransform.isInsertChange?(df)
        ladds[pos] = [] if ladds[pos].nil?
        ladds[pos] << df
      elsif DeltaTransform.isDeleteChange?(df)
        ldels[pos] = true
      elsif DeltaTransform.isModifyChange?(df)
        lmods[pos] = df
      end
    end
    #iterate along f, applying changes at each index
    # note that insertion MUST occur before modification because
    # "insert at 3" means "just before 3"
    i = 0
    old_l = []+o[fname].values #adding to [] will force the creation of a new array
    max_pos = old_l.length #one more than length of array because insertion can occur at the end
    for i in 0..max_pos
      if not ladds[i].nil? 
        #(sequentially) add new elements
        ladds[i].each do |x|
          res << add_obj(x, factory)
        end
      end
      if i < old_l.length #no need to check for deletions and modifications when past end of array
        if not lmods[i].nil?
          #if modified, replace current copy with new object
          o[fname] << patch_obj(old_l[i], lmods[i], factory)
        elsif not ldels[i]
          #if not deleted, copy into new array 
          res << old_l[i]
        end
      end
    end
    return res
  end

  def patch_keyedlist(o, fname, deltas, factory)
    res = []+o[fname].values
    deltas.each do |df|
      pos = df.pos
      if DeltaTransform.isInsertChange?(df)
        res.delete(o[fname][pos]) if not o[fname][pos].nil?
        res << add_obj(df, factory)
      elsif DeltaTransform.isDeleteChange?(df)
        res.delete(o[fname][pos]) if not o[fname][pos].nil?
      elsif DeltaTransform.isModifyChange?(df)
        new = patch_obj(o[fname][pos], df, factory)
        res.delete(o[fname][pos]) if not o[fname][pos].nil?
        res << new
      end
    end
    return res
  end

  def patch_refs!(o)

    o.schema_class.fields.each do |f|
      next if f.type.Primitive?
      if f.traversal
        if not f.many
          patch_refs!(o[f.name])
        else
          o[f.name].each {|x|patch_refs!(x)}
        end
      else
        if not f.many
          o[f.name] = @new_name_map.key(@old_name_map[o[f.name]])
        else
          old_l = []+o[f.name].values
          o[f.name].clear()
          old_l.each do |x|
            o[f.name] << @new_name_map.key(@old_name_map[x])
          end
        end
      end
    end
  end

end

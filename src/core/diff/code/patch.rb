=begin

Apply a diff result conforming to delta schema as a patch script on an object

=end

require 'core/system/library/schema'

class Patch

  def self.patch!(o, delta)
    return Patch.patch_obj!(o, delta)
  end


  
  #############################################################################
  #start of private section  
  private
  #############################################################################
  
  def self.patch_obj!(o, deltas)
    # accepts an object o conforming to schema
    # and deltas conforming to delta-schema
    # to produce an output o' conforming to schema

    if DeltaTransform.isPrimitive?(deltas)
      #if this is a primitive object apply the changes directly
      return DeltaTransform.getValue(deltas)
    else
      # apply changes to each of its fields
      schema_class = o.schema_class
      factory = Factory.new(o.schema_class.schema)

      schema_class.fields.each do |f|
        next if !f.type.Primitive? and !f.traversal
        #get field value 
        d = deltas[f.name]
        next if d.nil? #field is nil means it was not changed
        if not f.many
          patch_single!(o, f.name, d, factory)
        else #many-valued field
          if IsKeyed?(f.type)
            patch_keyedlist!(o, f.name, d, factory)
          else
            patch_orderedlist!(o, f.name, d, factory)
          end 
        end
      end
    end

    return o
  end

  # create a new object based on delta
  def self.add_obj(delta, factory)

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
          obj[f.name] = []
          delta[f.name].each do |x|
            obj[f.name] << add_obj(x, factory)
          end
        end
      end
    end

    return obj
  end

  def self.patch_single!(o, fname, delta, factory)
    #check which type of change this was
    if DeltaTransform.isInsertChange?(delta)
      o[fname] = patch_obj!(o[fname], delta)
    elsif DeltaTransform.isDeleteChange?(delta)
      o[fname] = nil
    elsif DeltaTransform.isModifyChange?(delta)
      o[fname] = patch_obj!(o[fname], delta)
    elsif DeltaTransform.isClearChange?(delta)
      #do nothing
    end
  end

  def self.patch_orderedlist!(o, fname, deltas, factory)
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
    o[fname].clear
    max_pos = old_l.length #one more than length of array because insertion can occur at the end
    for i in 0..max_pos
      if not ladds[i].nil? 
        #(sequentially) add new elements
        ladds[i].each do |x|
          o[fname] << add_obj(x, factory)
        end
      end
      if i < old_l.length #no need to check for deletions and modifications when past end of array
        if not lmods[i].nil?
          #if modified, replace current copy with new object
          o[fname] << patch_obj!(old_l[i], lmods[i])
        elsif not ldels[i]
          #if not deleted, copy into new array 
          o[fname] << old_l[i]
        end
      end
    end
  end

  def self.patch_keyedlist!(o, fname, deltas, factory)
    deltas.each do |df|
      pos = df.pos
      if DeltaTransform.isInsertChange?(df)
        o[fname].delete(pos)
        o[fname] << patch_obj!(o[fname][pos], df)
      elsif DeltaTransform.isDeleteChange?(df)
        o[fname].delete(pos)
      elsif DeltaTransform.isModifyChange?(df)
        o[fname].delete(pos)
        o[fname] << patch_obj!(o[fname][pos], df)
      end
    end
  end

end

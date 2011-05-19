=begin

Apply a diff result conforming to delta schema as a patch script on an object

=end

class Patch

  def self.patch!(o, deltas)
    # accepts an object o conforming to schema
    # and deltas conforming to delta-schema
    # to produce an output o' conforming to schema

    if DeltaTransform.isPrimitive?(deltas)
      #if this is a primitive object apply the changes directly
      return DeltaTransform.getValue(deltas)
    else
      # apply changes to each of its fields
      schema_class = deltas.schema_class
      factory = Factory.new(o.schema_class.schema)
  
      schema_class.fields.each do |f| #TODO: refactor this big loop into many smaller function calls
        #get field value 
        d = deltas[f.name]
        #field is nil means it was not changed
        next if d.nil?
        if not f.many
          #check which type of change this was
          if DeltaTransform.isInsertChange?(d)
            o[f.name] = patch!(o[f.name], d)
          elsif DeltaTransform.isDeleteChange?(d)
            o[f.name] = nil
          elsif DeltaTransform.isModifyChange?(d)
            o[f.name] = patch!(o[f.name], d)
          elsif DeltaTransform.isClearChange?(d)
            #do nothing
          end
        else #many-valued field
          #group all changes up by position
          ladds = {}
          ldels = {}
          lmods = {}
          max_pos = -1
          d.each do |df|
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
          old_l = []+o[f.name].values #adding to [] will force the creation of a new array
          o[f.name].clear
          max_pos = old_l.length #one more than length of array because insertion can occur at the end
          for i in 0..max_pos
            if not ladds[i].nil? 
              #(sequentially) add new elements
              ladds[i].each do |x|
                o[f.name] << add_obj(x, factory)
              end
            end
            if i < old_l.length #no need to check for deletions and modifications when past end of array
              if not lmods[i].nil?
                #if modified, replace current copy with new object
                o[f.name] << patch!(old_l[i], lmods[i])
              elsif not ldels[i]
                #if not deleted, copy into new array 
                o[f.name] << old_l[i]
              end
            end
          end
        end
      end
    end

    return o
  end


  
  #############################################################################
  #start of private section  
  private
  #############################################################################

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
    
end

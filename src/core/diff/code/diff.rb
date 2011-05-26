
require 'core/schema/code/factory'
require 'core/diff/code/delta'
require 'core/diff/code/delta_erb'
require 'core/diff/code/match'
require 'core/diff/code/equals'
require 'core/system/library/schema'

class Diff

  def diff (schema, o1, o2)
    #result of a diff is a graph that conforms to specified schema
    # nodes and edges in the graph are the union of the nodes in both instances
    # furthermore, every node is marked with a delta type: A(dded), D(eleted), M(odified)
    # every attribute (which includes edges) is marked with both old and new values

    # do some initialization
    @schema = schema
    @factory = Factory.new(DeltaERB.delta(schema))
    @rootobj = o2
    
    # generate name map based on o2
    @namemap = generate_name_map(o2, "")

    # do matching
    matches = Match.new.match(o1, o2)

    # generate union based on matches. union forms a basis for the result set
    return generate_diffs(o1, o2, matches)

  end

  
    
  #############################################################################
  #start of private section  
  private
  #############################################################################

  #generate a modified object that (might have been) changed between versions
  #if o1 and o2 and all their descendants are perfect matches, then return nil
  def generate_diffs(o1, o2, matches)
    # given a set of matches between the sub objects of o1 and o2
    #produce an annotated diff result conforming to dschma
    #this function is primarily a recursive postfix traversal of the spanning tree

    res = generate_matched_diff(o1, o2, matches)
#    if res.nil?
#      res = @factory[DeltaTransform.clear + o1.schema_class.name]
#    end
    return res
  end

  #create a completely new object with its complete subtree
  def generate_added_diff(field, o1)
    
    #if non primitive then recurse downwards
    if field.type.Primitive?
      x = @factory[DeltaTransform.insert + field.type.name]
      x.val = o1
    elsif !field.traversal # this is a ref type
      x = @factory[DeltaTransform.insert + DeltaTransform.ref]
      x.path = @namemap[o1]
    else
      x = @factory[DeltaTransform.insert + o1.schema_class.name]
      o1.schema_class.fields.each do |f|
        next if o1[f.name].nil?  # this optional field is not used

        if not f.many
          x[f.name] = generate_added_diff(f, o1[f.name])
        else
          reftype = f.traversal ? "" : ClassKey(f.type).type.name

          if IsKeyed? f.type
            o1[f.name].keys.each do |k|
              x[f.name] << DeltaTransform.manyify(generate_added_diff(f, o1[f.name][k]), @factory, k, reftype)
            end
          else
            o1[f.name].each do |l|
              #all items added at index 0 because it was originally empty
              x[f.name] << DeltaTransform.manyify(generate_added_diff(f, l), @factory, 0, reftype)
            end
          end
        end
      end
    end

    return x
  end

  #create a deleted object (no subtree)
  def generate_deleted_diff(field)
    if field.traversal or field.type.Primitive
      return @factory[DeltaTransform.delete + field.type.name]
    else
      return @factory[DeltaTransform.delete + DeltaTransform.ref]
    end
  end
  
  def generate_matched_orderedlist_diff(field, l1, l2, matches)

    keyed = IsKeyed? field.type
    
    reftype = field.traversal ? "" : ClassKey(field.type).type.name

    res = []
    
    # generate insert, modification and delete records for this list.
    # the canonical form requires that records are in the order ins-mod-del
    
    #for each unmatched item from l2, add an added record
    last_j = 0
    for j in l2.keys do
      if not matches.has_value?(l2[j])
        res << DeltaTransform.manyify(generate_added_diff(field, l2[j]), @factory, keyed ? j : last_j, reftype)
        modified = true
      else
        last_j = l1.find_index(matches.key(l2[j]))+1
      end
    end
    #for each pair of matched items, traverse the tree to figure out if we need to make an object
    matches.keys.each do |o|
      if l1.include?(o)
        keyname = keyed ? ClassKey(field.type).name : ""
        if field.traversal #recurse down the tree
          x = generate_matched_diff(o, matches[o], matches)
          if not x.nil?
            res << DeltaTransform.manyify(x, @factory, keyed ? o[keyname] : l1.find_index(o), reftype)
          end
        else #build a ref
          if not ( matches[o[keyname]] = matches[o][keyname] ) # check if they point to matching objects
            x = @factory[DeltaTransform.many + DeltaTransform.modify + DeltaTransform.ref + reftype]
            x.path = @namemap[matches[o][keyname]]
            x.pos = keyed ? o[keyname] : l1.find_index(o)
          end
        end
      end
    end
    #for each unmatched item from l1, add a deleted record
    for i in l1.keys do
      if not matches.has_key?(l1[i])
        res << DeltaTransform.manyify(generate_deleted_diff(field), @factory, i, reftype)
        modified = true
      end
    end

    return nil if res.empty?
    return res
  end
  
  def generate_matched_single_diff(field, o1, o2, matches)

    #handle optional fields that were added or deleted
    if o1.nil? and o2.nil?  # does nothing if both are nil
      return nil
    elsif o1.nil?  #field is added
      return generate_added_diff(field.type, o2)
    elsif o2.nil?  #field is deleted
      return generate_deleted_diff(field.type)
    end
    
    #handle primitives
    if field.type.Primitive? 
      return o1==o2 ? nil : generate_added_diff(field, o2)
    end
    
    #handle refs
    if not field.traversal
      matches[o1] == o2 ? nil : generate_added_diff(field, o2)
    end

    #handle normal objects    
    if field.traversal 
      return matches[o1] == o2 ? generate_matched_diff(o1, o2, matches) : generate_added_diff(field, o2)
    end
  end

  def generate_matched_diff(o1, o2, matches)

    # given a set of matches between the sub objects of o1 and o2
    #produce an annotated diff result conforming to dschma
    #the result will be a ModifyClass
    # the assumption is that: o1, o2, and the returned object have the same type

    #traverse descendants to discover changes

    #find common, added, and deleted fields
    schema_class = o1.schema_class
    diff_fields = {}

    #generate diffs for each field
    schema_class.fields.each do |f|

      f1 = o1[f.name]
      f2 = o2[f.name]
      type = f.type

      if not f.many
        d = generate_matched_single_diff(f, f1, f2, matches)
      else
        d = generate_matched_orderedlist_diff(f, f1, f2, matches)
      end

      if not d.nil?
        diff_fields[f.name] = d
      end
    end

    # create object using consolidated change records from descendants 
    
    #if no fields have been altered, return nil
    return nil if diff_fields.empty?
    new1 = @factory[DeltaTransform.modify + schema_class.name]
    diff_fields.keys.each do |fn|
      if schema_class.fields[fn].many
        diff_fields[fn].each do |i|
          new1[fn] << i
        end
      else
        new1[fn]=diff_fields[fn]
      end
    end
    return new1
  end

  def generate_name_map(obj, path)
    res = {obj => path}
    delim = path.empty? ? "" : "."  # first item does not have delimiter
    obj.schema_class.fields.each do |f|
      #TODO: Naming system (based on library/schema.lookup) only supports many fields
      next unless f.traversal and f.many
      
      obj[f.name].keys.each do |k|
        res.merge!(generate_name_map(obj[f.name][k], path + delim + k.to_s))
      end
    end
    return res
  end

end


def diff(x, y)
  Diff.new.diff(x.schema_class.schema, x, y)
end

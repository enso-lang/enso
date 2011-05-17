
require 'core/diff/code/delta'
require 'core/diff/code/match'
require 'core/diff/code/equals'

class Diff

  def diff (schema, o1, o2)
    #result of a diff is a graph that conforms to specified schema
    # nodes and edges in the graph are the union of the nodes in both instances
    # furthermore, every node is marked with a delta type: A(dded), D(eleted), M(odified)
    # every attribute (which includes edges) is marked with both old and new values
  end

  def diff_line (schema, o1, o2)
    #do differencing for the geometry-diff sample --- only as a trial!

    # do some initialization
    @schema = schema
    @factory = Factory.new(DeltaTransform.new.delta(schema))

    # initialize strategies
    @match = Match.new(Equals.new)

    # do matching
    matches = @match.match(o1, o2)
#    puts matches
    
    # generate union based on matches. union forms a basis for the result set
    res = generate_diffs(o1, o2, matches)
#    puts res.schema_class.name
#    puts res.pts.length
  end

  def match_primitive (schema, o1, o2)
    if (eq_primitive(schema, o1, o2))
      return { o1 => o2 }
    else
      return {}
    end
  end

  #create a completely new object with its complete subtree
  def generate_added_diff(o1, *pos)
    if pos.length>0 #this is a many field
      x = @factory[DeltaTransform.many + DeltaTransform.insert + o1.schema_class.name]
#      x.pos = pos[0]
      return x
    else
      return @factory[DeltaTransform.insert + type.name]
    end  
  end

  #create a deleted object (no subtree)
  #an explicit type is necessary because o1 can be a subtype
  def generate_deleted_diff(o1, *pos)
    if pos.length>0 #this is a many field
      x = @factory[DeltaTransform.many + DeltaTransform.delete + o1.schema_class.name]
#      x.pos = pos[0]
      return x
    else
      return @factory[DeltaTransform.delete + type.name]
    end  
  end

  #generate a modified object that (might have been) changed between versions
  #if o1 and o2 and all their descendants are perfect matches, then return nil
  def generate_matched_diff(o1, o2, matches, *pos)
    # given a set of matches between the sub objects of o1 and o2
    #produce an annotated diff result conforming to dschma
    #the result will be a ModifyClass
    # the assumption is that: o1, o2, and the returned object have the same type
    
  end

  def generate_diffs(o1, o2, matches)
    # given a set of matches between the sub objects of o1 and o2
    #produce an annotated diff result conforming to dschma
    #this function is primarily a recursive postfix traversal of the spanning tree

    #traverse descendants to discover changes    

    #find common, added, and deleted fields
    schema_class = o1.schema_class
    modified = false
    diff_fields = {}
    schema_class.fields.each do |f|
      if f.traversal
        #generate diffs for each field
        if f.Primitive? 
          if f.many
            res = []
            l1 = o1.method(f.name).call
            l2 = o2.method(f.name).call
            lcm_matches = lcm(l1, l2, 0, 0, {}, lambda{|x,y| eq(schema, x, y)})
            #for each unmatched item from l1, add a deleted primitive
            for i in 0..l1.length-1 do
              if not lcm_matches.has_key?(i)
                res << generate_deleted_diff(o1, type, i)
                modified = true
              end
            end
              #for each unmatched item from l2, add an added primitive
            last_j = 0
            for j in 0..l2.length-1 do
              if not lcm_matches.has_value?(j)
                res << @factory[DeltaTransform.many + DeltaTransform.insert + f.type.name]
                modified = true
              else
                last_j = lcm_matches.key(j)
              end
            end
            if modified
              diff_fields[f.name] = res
            end
          else
            if o1.method(f.name).call == o2.method(f.name).call
              #do nothing for unchanged primitives
            else
              diff_fields[f.name] = @factory[DeltaTransform.modify + f.type.name]
              modified = true
            end
          end
        else  # not primitive and many
          if f.many
            res = []
            l1 = o1.method(f.name).call
            l2 = o2.method(f.name).call
            #for each pair of matched items, traverse the tree to figure out if we need to make an object
            matches.keys.each do |i|
              x = generate_matched_diff(i, matches[i], matches, i)
              if not x.nil?
                res << x
              end
            end 
            #for each unmatched item from l1, add a deleted record
            for i in 0..l1.length-1 do
              if not matches.has_key?(l1[i])
                res << generate_deleted_diff(o1, i)
                modified = true
              end
            end
            #for each unmatched item from l2, add an added record
            last_j = 0
            for j in 0..l2.length-1 do
              if not matches.has_value?(l2[j])
                res << generate_added_diff(o1, last_j)
                modified = true
              else
                last_j = matches.key(l2[j])
              end
            end
            if not res.empty?
              diff_fields[f.name] = res
            end
          else # not primitive and single
            if matches[o1] = o2
              # matched target object
              x = generate_matched_diff(old1, old2, matches)
              if not x.nil?
                diff_fields[f.name] = x
              end
            else
              # not matched target objects
              diff_fields[f.name] = generate_added_diff(o2)
              modified = true
            end
          end
        end
      end
    end
    
    # create object using consolidated change records from descendants 
    
    #if no fields have been altered, return nil
    if diff_fields.empty?
      return nil
    end
    
    #if no direct field was altered (ie only descendants have been changed)
    #then mark this class as unchanged
    if modified
      new1 = @factory[DeltaTransform.modify + schema_class.name]
    else 
      new1 = @factory[DeltaTransform.clear + schema_class.name]
    end

    #copy delta fields from descendant records
    diff_fields.keys.each do |fn|
      if schema_class.fields[fn].many
        diff_fields[fn].each do |i|
          new1.[](fn) << i
        end
      else
        new1.[]=(fn, diff_fields[fn])
      end
    end
    return new1

  end

  def shallow_copy(from, to)
    #similar to obj.clone() except two objects can have different types
    # only primitive fields found in both types will be copied
    schema_class1 = o1.schema_class
    schema_class2 = o2.schema_class
    fields = []
    schema_class1.fields do |f1|
      schema_class2.fields do |f2|
        if f1.name == f2.name() && f1.type.Primitive? && f2.type.Primitive?
          fields << f1.name
        end
      end
    end
    fields do |fn|
      if o1.method(f.name).call != o2.method(f.name).call 
        o2.[]=(f.name, o1.[](f,name))
      end
    end
  end

end


def diff(x, y)
  Diff.new.diff(x.schema_class.schema, x, y)
end

if __FILE__ == $0 then

  require 'core/system/load/load'
  require 'core/schema/tools/print'
  
  cons = Loader.load('point.schema')
  
  ss = Loader.load('schema.schema')
  gs = Loader.load('grammar.schema')
  delta = diff(ss, gs)

  Print.print(delta)
end

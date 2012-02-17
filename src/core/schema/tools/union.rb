require 'core/system/load/load'
require 'core/schema/code/factory'

require 'core/grammar/render/layout'

=begin

This file creates the copy of two structures.
The copy U of structures A and B has all the
objects of both A and B.

=end

class CopyInto
  def initialize(factory)
    @memo = {}
    @factory = factory
  end

  # computes the copy of structures given root nodes a and b  
  def copy(a, b)
    build(a, b)
    return link(true, a, b)
  end
  
  # build walks the spine of the two structures and matches up
  # corresponding objects. The most important thing to keep in 
  # mind is that either a or b (or both) can be nil, if there is no
  # corresponding structure in the other structure.
  # This function builds all the new objects and also initialized
  # the primitive fields. Primitive fields must be initialized
  # first so that the keys will be defined before objects are added
  # to keyed collections
  def build(a, b)
    return if a.nil?
    raise "Union of incompatible objects #{a} and #{b}" if a && b && a.schema_class.name != b.schema_class.name
    @memo[a] = new = b || @factory[a.schema_class.name]
    #puts "BUILD #{a} + #{b} ==> #{new}"
    a.schema_class.fields.each do |field|
      a_val = a[field.name]
      b_val = b && b[field.name]
      #puts "#{field.name} #{field.traversal}: #{a_val} / #{b_val}"
      if field.type.Primitive?
        if a && b && a_val != b_val then
          puts "UNION WARNING: changing #{a}.#{field.name} from '#{a_val}' to '#{b_val}'" 
        end
        new[field.name] = a_val
      elsif field.traversal
        if !field.many
          build(a_val, b_val)
        else
          a_val.join(b_val) do |a_item, b_item|
            build(a_item, b_item)
          end
        end
      end
    end
  end

  # creates the cross-links in the CopyInto. The "traversal" field is used
  # to go one stage past the spine, to relate linked objects.
  def link(traversal, a, b)
    return b if a.nil?
    new = @memo[a]
    #puts "LINK #{a} + #{b} ==> #{new}"
    raise "Traversal did not visit every object a=#{a} b=#{b}" unless new
    return new if !traversal
    a.schema_class.fields.each do |field|
      a_val = a[field.name]
      b_val = b && b[field.name]
      next if field.type.Primitive?
      if !field.many
        val = link(field.traversal, a_val, b_val)
        new[field.name] = val
      else
        a_val.join(b_val) do |a_item, b_item|
          item = link(field.traversal, a_item, b_item)
          new[field.name] << item unless new[field.name].include? item
        end
      end
    end
    return new
  end

end        

def CopyInto(factory, a, b)
  return CopyInto.new(factory).copy(a, b)
end   

def Copy(factory, a)
  return CopyInto.new(factory).copy(a, nil).finalize
end

def Clone(a)
  return Copy(a.factory, a)
end
    
def Union(factory, *parts)
  copier = CopyInto.new(factory)
  result = nil
  parts.each do |part|
    result = copier.copy(part, result)
  end
  return result.finalize
end   


def union(a, b)
  f = ManagedData::Factory.new(a._graph_id.schema)
  Union(f, a, b)
end

require 'core/system/load/load'
require 'core/grammar/code/layout'

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
    new.schema_class.fields.each do |field|
      a_val = a[field.name]
      b_val = b && b[field.name]
      #puts "#{field.name} #{field.traversal}: #{a_val} / #{b_val}"
      if field.type.Primitive?
        puts "UNION WARNING: changing #{a}.#{field.name} from '#{a_val}' to '#{b_val}'" if a && b && a_val != b_val
        new[field.name] = a_val
      elsif field.traversal
        if !field.many
          build(a_val, b_val)
        else
          do_join(field, a_val, b_val) do |a_item, b_item|
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
    raise "Traversal did not visit every object #{a} #{b}" unless new
    return new if !traversal
    new.schema_class.fields.each do |field|
      a_val = a[field.name]
      b_val = b && b[field.name]
      next if field.type.Primitive?
      if !field.many
        val = link(field.traversal, a_val, b_val)
        new[field.name] = val
      else
        do_join(field, a_val, b_val) do |a_item, b_item|
          new[field.name] << link(field.traversal, a_item, b_item)
        end
      end
    end
    return new
  end

  # matches keyed fields, but concatenates ordered fields
  def do_join(field, a, b)
    key = ClassKey(field.type)
    if key
      empty = ManyIndexedField.new(key.name)
      (a || empty).outer_join(b || empty) do |sa, sb|
        yield sa, sb
      end
    elsif !a.empty?
      a.each do |item|
        yield item, nil
      end
    end        
  end
end        

def CopyInto(factory, a, b)
  return CopyInto.new(factory).copy(a, b)
end   

def Copy(factory, a)
  return CopyInto.new(factory).copy(a, nil).finalize
end   
    
def Union(factory, a, b)
  return CopyInto.new(factory).copy(a, Copy(factory, b)).finalize
end   



require 'core/system/load/load'
require 'core/grammar/code/layout'

=begin

This file creates the union of two structures.
The union U of structures A and B has all the
objects of both A and B.

=end

class Union
  def initialize(factory)
    @memo = {}
    @factory = factory
  end

  # computes the union of structures given root nodes a and b  
  def union(a, b)
    build(a, b)
    result = link(true, a, b)
    result.finalize
    return result
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
    return nil if a.nil? && b.nil?
    klass = ClassMinimum(a && a.schema_class, b && b.schema_class)
    raise "Union of incompatible objects #{a} and #{b}" if !klass
    new = @memo[a] = @memo[b] = @factory[klass.name]
    #puts "BUILD #{a} + #{b} ==> #{new}"
    klass.fields.each do |field|
      a_val = a && a[field.name]
      b_val = b && b[field.name]
      #puts "#{field.name} #{field.traversal}: #{a_val} / #{b_val}"
      if field.type.Primitive?
        puts "UNION WARNING: changing #{a}.#{field.name} from '#{a_val}' to '#{b_val}'" if a && b && a_val != b_val
        new[field.name] = b ? b_val : a_val
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

  # creates the cross-links in the union. The "traversal" field is used
  # to go one stage past the spine, to relate linked objects.
  def link(traversal, a, b)
    return nil if a.nil? && b.nil?
    new = @memo[a || b]
    #puts "LINK #{a} + #{b} ==> #{new}"
    raise "Traversal did not visit every object #{a} #{b}" unless new
    return new if !traversal
    new.schema_class.fields.each do |field|
      a_val = a && a[field.name]
      b_val = b && b[field.name]
      next if field.type.Primitive?
      if !field.many
        new[field.name] = link(field.traversal, a_val, b_val)
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
    else
      empty = ManyField.new
      ((a || empty) + (b || empty)).each do |item|
        yield item, nil
      end
    end        
  end
end        
          

if __FILE__ == $0 then

  gs = Loader.load('grammar.schema')
  gg = Loader.load('grammar.grammar')
  ss = Loader.load('schema.schema')
  sg = Loader.load('schema.grammar')
  
  require 'core/schema/tools/print'
  
  x = Union.new(Factory.new(ss))
  result = x.union(ss, gs)
  #Print.print(result)
  DisplayFormat.print(sg, result)
  puts "-"*50
  
  x = Union.new(Factory.new(gs))
  result = x.union(sg, gg)
  #Print.print(result)
  DisplayFormat.print(gg, result)

end

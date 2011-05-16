require 'core/system/load/load'
require 'core/grammar/code/layout'

class Union
  def initialize(factory)
    @left_memo = {}
    @right_memo = {}
    @factory = factory
  end
  
  def union(a, b)
    build(a, b)
    result = link(true, a, b)
    result.finalize
    return result
  end
  
  def build(a, b)
    return nil if a.nil? && b.nil?
    klass = ClassMinimum(a && a.schema_class, b && b.schema_class)
    raise "Union of incompatible objects #{a} and #{b}" if !klass
    new = @factory[klass.name]
    #puts "BUILD #{a} + #{b} ==> #{new}"
    @left_memo[a] = new if a
    @right_memo[b] = new if b
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
          do_join(field, a_val, b_val) do |k, a_item, b_item|
            build(a_item, b_item)
          end
        end
      end
    end
  end

  def link(traversal, a, b)
    return nil if a.nil? && b.nil?
    new = @left_memo[a] || @right_memo[b]
    #puts "LINK #{a} + #{b} ==> #{new}"
    raise "Traversal did not visit every object #{a} #{b}" unless new
    if traversal
      new.schema_class.fields.each do |field|
        a_val = a && a[field.name]
        b_val = b && b[field.name]
        next if field.type.Primitive?
        if !field.many
          new[field.name] = link(field.traversal, a_val, b_val)
        else
          do_join(field, a_val, b_val) do |k, a_item, b_item|
            new[field.name] << link(field.traversal, a_item, b_item)
          end
        end
      end
    end
    return new
  end

  def do_join(field, a, b)
    if a.nil?
      b.each_with_index do |sb, k|
        yield k, nil, sb
      end
    elsif b.nil?
      a.each_with_index do |sa, k|
        yield k, sa, nil
      end
    else
      if ClassKey(field.type)
        a.outer_join(b) do |sa, sb, k|
          yield k, sa, sb
        end
      else
        n = 0
        a.each do |item|
          yield n, item, nil 
          n += 1
        end
        b.each do |item|
          yield n, nil, item
          n += 1
        end
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

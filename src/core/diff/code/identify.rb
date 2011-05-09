require 'core/system/load/load'
require 'core/system/library/schema'

class Identify
  def initialize()
    @left_to_right = {}
    @right_to_left = {}
  end
  
  def apply(type, a, b)
    #puts "#{a} === #{b}  #{!a || !b}"
    # raise "cannot identify primitive types" if type.Primitive?
    return if !a || !b
    if @left_to_right[a]
      raise "inconsistent identification" unless @left_to_right[a] == b
      return
    end
    raise "incompatible classes" if a.schema_class.name != b.schema_class.name
    identify(a, b)
    klass = type.schema.classes[a.schema_class.name]
    #puts "KLASS #{klass}"
    klass.fields.each do |field|
      asub = a[field.name]
      bsub = b[field.name]
      if !field.many
        apply(field.type, asub, bsub) if !field.type.Primitive? && asub && bsub 
      elsif ClassKey(field.type) # TODO: could be an option to identify ordered fields???
        asub.outer_join(bsub) do |k, d1, d2|
          apply(field.type, d1, d2) if d1 && d2
        end
      end
    end
  end

  def identify(a, b)
    @left_to_right[a] = b
    @right_to_left[b] = a
  end    

  def dump()
    puts @left_to_right
  end
end

if __FILE__ == $0 then

  gs = Loader.load('grammar.schema')
  gg = Loader.load('grammar.grammar')
  ss = Loader.load('schema.schema')
  sg = Loader.load('schema.grammar')
  
  require 'core/schema/tools/print'
  
  x = Identify.new()
  x.apply(gs.classes["Grammar"], gg, sg)
  x.dump
  puts "-"*50
  
  x = Identify.new()
  x.apply(ss.classes["Schema"], gs, ss)
  x.dump

end





require 'core/system/load/load'
require 'core/system/library/schema'
require 'core/diff/code/identify'

class Diff

  def initialize(factory)
    @memo = {}
    @factory = factory
    @empty = ManyField.new
    @indent = 0
  end

  def diff(a, b)
    @identity = Identify.new()
    @identity.apply(a.schema_class, a, b)
    return recurse(a, b)
  end
  
  def myputs(s)
    puts "#{' '*@indent}#{s}"
  end
  
  def recurse(a, b, wasIdentified = true)
    begin
      @indent += 2
      return nil if !a && !b
      myputs "#{a}/#{@identity.right_to_left[b]} === #{b}/#{@identity.left_to_right[a]}"
      return {action: a.schema_class.name + "Delete"} if !b #FOO
      return @factory[a.schema_class.name + "Delete"] if !b
      a = @identity.right_to_left[b] if !a
      b = @identity.left_to_right[a] if !b
      thisIdentified = b && (b == @identity.left_to_right[a])
      # moved from un-identify to identified
      if thisIdentified && !wasIdentified
        myputs "####"
        return nil
      end
      klass = ClassMinimum(a && a.schema_class, b && b.schema_class)
      if !klass
        klass = b.schema_class
        a = nil
      end
      #puts "KLASS #{klass}"
      puts "*MEMOED*" if @memo[[a, b]]
      return nil if @memo[[a, b]]
      @memo[[a, b]] = true
      result = nil
      klass.fields.each do |field|
        asub = a && a[field.name]
        bsub = b && b[field.name]
        if !field.many
          if field.type.Primitive?
            result = self.prim(field.type, asub, bsub)        
          else
            result = self.bind(result, field, recurse(asub, bsub, thisIdentified))
          end
        else
          (asub || @empty).outer_join(bsub || @empty) do |d1, d2, k|
            change = recurse(d1, d2, thisIdentified)
            
            change["pos"] = k if change
            #change.pos = k if change
            
            result = self.bind(result, field, change)
          end
        end
      end
      if result
        # have to go back and patch up and identifications
      end
      myputs "** #{result}" if !a 
      return result
    ensure
      @indent -= 2
    end
  end
  
  def prim(type, a, b)
    return nil if a == b

    return {action: type.name + "Delete"} if b.nil? #FOO
    return @factory[type.name + "Delete"] if b.nil?
    
    return {action: type.name + "Modify", from: a, to: b} #FOO
    result = @factory[type.name + "Modify"]
    result.value = b   # TODO: SHOULD BE r.value
    return result
  end
  
  def bind(result, field, v)
    if v
      result = {} if result.nil? #FOO
      #result = @factory[field.owner.name + "Modify"] if !result
      if !field.many
        result[field.name] = v
      else
        result[field.name] = [] if result[field.name].nil? #FOO
        result[field.name] << v
      end
    end
    return result
  end
  
end  

       
if __FILE__ == $0 then

  gs = Loader.load('grammar.schema')
  gg = Loader.load('grammar.grammar')
  ss = Loader.load('schema.schema')
  sg = Loader.load('schema.grammar')
  
  require 'core/schema/tools/print'
  
  x = Diff.new(nil)
  d = x.diff(gg, gg)
  puts d

  puts "-"*50
  
  x = Diff.new(nil)
  d = x.diff(gs, ss)
  puts d

end
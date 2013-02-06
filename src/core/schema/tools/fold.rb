
require 'yaml'
require 'core/system/library/schema'

class AbstractFold
  def initialize(mod)
    @mod = mod
    @memo = {}
  end

  def fold(scls, obj)
    return if obj.nil?
    if @memo[obj] then
      return @memo[obj]
    end
    scls, cls = lookup_class(obj, scls) 
    puts "CLASS: #{cls} (for #{obj})"
    if cls.nil? then
      return obj # original model
    end
    @memo[obj] = trg = cls.new
    update_fields(obj, trg, scls.fields)
    return trg
  end

  def update_fields(obj, trg, fields)
    fields.each do |f|
      puts "\tsetting #{f.name}"
      if f.type.Primitive? then
        update_prim(obj, trg, f)
      else
        update_ref(obj, trg, f)
      end
    end
  end

  def lookup_class(obj, scls)
    #puts "Classname obj: #{class_name(obj)}"
    if @mod.const_defined?(class_name(obj)) then
      return class_of(obj), @mod.const_get(class_name(obj))
    elsif @mod.const_defined?(scls.name) then
      return scls, @mod.const_get(scls.name)
    else
      $stderr << "WARNING: no (super)class for #{scls.name}\n"
      nil
    end
  end


  def update_prim(obj, trg, f)
    x = lookup(obj, f)
    puts "\t\t#{f.name} --> #{x}"
    set!(trg, f, x)
  end

  def update_ref(obj, trg, f)
    if f.many then
      update_many(obj, trg, f)
    else
      update_single(obj, trg, f)
    end
  end

  def update_many(obj, trg, f)
    puts "\tMANY (#{f.name})"
    coll = []
    lookup(obj, f).each do |x|
      puts "\t\telt = #{x}"
      other = fold(f.type, x)
      coll << other
      update_inverse(obj, trg, f, other)
    end
    set!(trg, f, coll)
  end

  def update_single(obj, trg, f)
    puts "Updating single: #{obj} into #{f.name}: #{f.type}"
    other = fold(f.type, lookup(obj, f))
    set!(trg, f, other)
    update_inverse(obj, trg, f, other)
  end

  def update_inverse(obj, trg, f, other)
    if f.inverse then
      if f.inverse.many && Schema::is_keyed?(f.type) then
        init_if_needed(other, f.inverse, {})
        get(other, f.inverse)[Schema::object_key(obj)] = trg
      elsif f.inverse.many then
        # TODO: this has the same problem as in factory;
        # should be done in finalize.
        init_if_needed(other, f.inverse, [])
        get(other, f.inverse) << trg
      else
        set!(other, f.inverse, trg)
      end
    end
  end

  def set!(trg, f, value)
    trg.instance_variable_set(ivar(f), value)
  end

  def get(trg, f)
    trg.instance_variable_get(ivar(f))
  end

  def init_if_needed(trg, f, value)
    return if trg.instance_variable_defined?(ivar(f))
    trg.instance_variable_set(ivar(f), value)
  end

  def ivar(f)
    "@#{f.name}"
  end
end

class Fold < AbstractFold
  def class_name(obj)
    class_of(obj).name
  end

  def class_of(obj)
    obj.schema_class
  end

  def lookup(obj, fld)
    obj[fld.name]
  end
end

class RubyFold < AbstractFold

  def lookup_class(obj, scls)
    _, cls = super(obj, scls)
    n = cls.name.split('::').last
    return scls.schema.classes[n], cls
  end

  def class_of(obj)
    obj.class
  end

  def class_name(obj)
    class_of(obj).name.split('::').last
  end

  def lookup(obj, fld)
    obj.instance_variable_get(ivar(fld))
  end
end


if __FILE__ == $0 then
  require 'core/system/load/load'
  require 'pp'
  
  module Schema
    class Schema
    end
    class Primitive
    end
    class Class
    end
    class Field
    end
  end

  module Grammar
    class Grammar
    end
    class Rule
    end
    class Alt
    end
    class Sequence
    end
    class Create
    end
    class Field
    end
    class Call
    end
    class Value
    end
    class Lit
    end
    class Regular
    end
  end


  #fold = Fold.new(Schema)
  #ss = Loader.load('state_machine.schema')
  fold = Fold.new(Grammar)
  ss = Loader.load('path.grammar')
  gs = Loader.load('grammar.schema')
  
  folded = fold.fold(gs.classes['Grammar'], ss)
  YAML.dump(folded, x = '')

  fold2 = RubyFold.new(Grammar)
  folded2 = fold2.fold(gs.classes['Grammar'], folded)
  YAML.dump(folded2, y = '')
  puts "X = Y? #{x == y}"
end

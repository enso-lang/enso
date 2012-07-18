
require 'yaml'
require 'core/system/library/schema'

class Fold

  def initialize(mod, *args)
    @mod = mod
    @args = args
    @memo = {}
  end

  def fold(obj)
    return if obj.nil?
    if @memo[obj] then
      return @memo[obj]
    end
    cls = lookup_class(obj.schema_class)
    if cls.nil? then
      return obj # original model
    end
    #puts "CREATING: #{cls}"
    @memo[obj] = trg = cls.new
    update_fields(obj, trg, obj.schema_class.fields)
    #puts "DONE: #{cls}"
    return trg
  end

  def update_fields(obj, trg, fields)
    fields.each do |f|
      #puts "\tsetting #{f.name}"
      if f.type.Primitive? then
        update_prim(obj, trg, f)
      else
        update_ref(obj, trg, f)
      end
    end
  end

  def lookup_class(scls)
    const = scls.name
    if !@mod.const_defined?(const) then
      $stderr << "WARNING: no class for #{const}\n"
      #return Object
      return nil
    end
    @mod.const_get(const)
  end


  def update_prim(obj, trg, f)
    #puts "\t\tprim: #{f.name} = #{obj[f.name]}"
    set!(trg, f, obj[f.name])
  end

  def update_ref(obj, trg, f)
    if f.many && IsKeyed?(f.type) then
      update_set(obj, trg, f)
    elsif f.many
      update_list(obj, trg, f)
    else
      update_single(obj, trg, f)
    end
  end

  def update_set(obj, trg, f)
    coll = {}
    obj[f.name].each do |x|
      # class keys are assumed to be primitive.
      other = fold(x)
      coll[ObjectKey(x)] = other
      update_inverse(obj, trg, f, other)
    end
    #puts "\t\tset: #{f.name} = #{coll.values.map { |x| x.class.name }.join(',')}"
    set!(trg, f, coll)
  end

  def update_list(obj, trg, f)
    coll = []
    obj[f.name].each do |x|
      other = fold(x)
      coll << other
      update_inverse(obj, trg, f, other)
    end
    #puts "\t\tlist: #{f.name} = #{coll.map { |x| x.class.name }.join(',')}"
    set!(trg, f, coll)
  end

  def update_single(obj, trg, f)
    other = fold(obj[f.name])
    set!(trg, f, other)
    update_inverse(obj, trg, f, other)
  end

  def update_inverse(obj, trg, f, other)
    if f.inverse then
      if f.inverse.many && IsKeyed?(f.type) then
        init_if_needed(other, f.inverse, {})
        get(other, f.inverse)[ObjectKey(obj)] = trg
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
  
  folded = fold.fold(ss)
  #pp folded
  YAML.dump(folded, $stdout)
end

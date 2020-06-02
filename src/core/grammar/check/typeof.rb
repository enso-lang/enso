

require 'core/grammar/check/multiplicity'
require 'core/grammar/check/types'
require 'core/grammar/check/deref-schema'



class TM
  attr_reader :type, :mult
  def initialize(type, mult)
    @type = type
    @mult = mult
    #if mult == Multiplicity::ZERO && type == GrammarTypes::VOID then
    #  raise "error"
    #end
  end

  def +(x)
    TM.new(type + x.type, mult + x.mult)
  end

  def *(x)
    TM.new(type + x.type, mult * x.mult)
  end

  def to_s
    "<#{type}, #{mult}>"
  end

  def ==(o)
    o.type == type && o.mult == mult
  end

  def eql?(o)
    self == o
  end

  def hashcode
    type.hashcode * 17 + mult.hashcode
  end
end


class TypeOf
  include GrammarTypes
  include Multiplicity

  #BOT = TM.new(VOID, ZERO)

  def initialize(schema, root)
    @schema = schema
    @root = root
    @errors = {}
    @memo = {}
  end

  def type_of(obj, klass, in_field, comb)
    #puts "SENDING to: #{obj.schema_class.name}"
    if respond_to?(obj.schema_class.name) then
      send(obj.schema_class.name, obj, klass, in_field, comb)
    else
      unit(comb)
    end
  end

  def Sequence(this, klass, in_field, comb)
    if this.elements.size == 0 then
      unit(comb)
    elsif this.elements.size == 1 then
      type_of(this.elements.first, klass, in_field, comb)
    else
      x = type_of(this.elements[0], klass, false, :*)
      1.upto(this.elements.size - 1) do |i|
        x *= type_of(this.elements[i], klass, false, :*)
      end
      return x
    end
  end

  def Call(this, klass, in_field, comb)
    if @memo[this]
      return @memo[this]
    end

    @memo[this] = unit(comb)

    x = type_of(this.rule, klass, in_field, comb)
    while x != @memo[this]
      @memo[this] = x
      x = type_of(this.rule, klass, in_field, comb)
    end
    return x
  end

  def Rule(this, klass, in_field, comb)
    if this.arg then
      type_of(this.arg, klass, in_field, comb) 
    else
      TM.new(VOID, ONE) # hack, we should not support abstract rules.
    end
  end

  def Alt(this, klass, in_field, comb)
    x = type_of(this.alts[0], klass, in_field, :+)
    1.upto(this.alts.size - 1) do |i|
      x += type_of(this.alts[i], klass, in_field, :+)
    end
    return x
  end

  def Create(this, klass, in_field, comb)    
    cls = @schema.classes[this.name]
    if cls then
      TM.new(Klass.new(cls), ONE)
    else
      @errors[this] = "No such class: #{this.name}";
      unit(comb)
      #return TM.new(VOID, ZERO)
    end
  end

  def Value(this, klass, in_field, comb)
    key = this.kind == 'sym' ? 'str' : this.kind
    TM.new(Primitive.new(@schema.primitives[key]), ONE)
  end

  def Ref(this, klass, in_field, comb)
    t = DerefSchema.new(@schema, @root).deref(this.path, klass)
    return unit(comb) if t.nil?
    if t.is_a?("Class") then
      TM.new(Klass.new(t), ONE)
    elsif t.is_a?("Primitive") then
      TM.new(Primitive.new(t), ONE)
    else
      raise "Inconsistent type: #{t}"
    end
  end

  def Lit(this, klass, in_field, comb)
    in_field ? TM.new(Primitive.new(@schema.primitives['str']), ONE) : unit(comb)
  end
    
  def Regular(this, klass, in_field, comb)
    tm = type_of(this.arg, klass, in_field, comb)
    if this.optional then
      TM.new(tm.type, this.many ? tm.mult.star : tm.mult.opt)
    elsif this.many
      TM.new(tm.type, tm.mult.plus)
    else
      raise "Invalid regular: #{this}" 
    end
  end

  def yield_objects(model, &block)
    return if model.nil?
    model.schema_class.fields.each do |fld|
      next if fld.type.is_a?("Primitive") || !fld.traversal 
      if fld.many then
        model[fld.name].each do |x|
          yield x
          yield_objects(x, &block)
        end
      else
        x = model[fld.name]
        yield x
        yield_objects(x, &block)
      end
    end
  end

  def unit(comb)
    if comb == :+ then
      TM.new(VOID, ONE)
    elsif comb == :* then
      TM.new(VOID, ZERO)
    else
      raise "Wrong comb: #{comb}"
    end
  end
end

module Bla
  def yield_objects(model, &block)
    return if model.nil?
    model.schema_class.fields.each do |fld|
      next if fld.type.is_a?("Primitive") || !fld.traversal 
      if fld.many then
        model[fld.name].each do |x|
          yield x
          yield_objects(x, &block)
        end
      else
        x = model[fld.name]
        yield x
        yield_objects(x, &block)
      end
    end
  end
end


if __FILE__ == $0 then
  include Bla

  if !ARGV[0] || !ARGV[1] || !ARGV[2] then
    puts "use typeof.rb <name>.grammar <name>.schema <rootclass>"
    exit!(1)
  end


  require 'core/system/load/load'
  require 'core/grammar/render/layout'

  require 'pp'

  g = Load::load(ARGV[0])
  s = Load::load(ARGV[1])
  start = ARGV[2]

  root_class = s.classes[start]

  to = TypeOf.new(s, root_class)

  test_class = s.classes["Regular"]
  puts to.type_of(g.start, test_class , true, :*)

  gg = Load::load('grammar.grammar')

  yield_objects(g) do |x|
    next if x.nil?
    next if x.is_a?("Lit")
    next if x.is_a?("Call")
    tm = to.type_of(x, test_class, true, :*)
    if tm.type != GrammarTypes::VOID then
      puts "#{x}: #{tm}"
    end
  end

  exit!

  g.rules.each do |rule|
    puts "RULE #{rule.name}: #{to.type_of(rule, test_class, true, :*)}"
    # rule.arg.alts.each do |alt|
    #   puts "\tALT: #{to.type_of(alt, test_class, true, :*)}"
    #   if alt.is_a?("Sequence") then
    #     alt.elements.each do |elt|
    #       puts "\t\tELT: #{to.type_of(elt, test_class, true, :*)}"
    #     end
    #   end
    #   if alt.is_a?("Create") && alt.arg.elements[0].is_a?("Field") then
    #     puts "\t\tFIELD: #{to.type_of(alt.arg.elements[0].arg, test_class, true, :*)}"
    #   end
    # end
  end
end

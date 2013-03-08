

require 'core/grammar/check/multiplicity'
require 'core/grammar/check/types'
require 'core/grammar/check/deref-type'



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
    TM.new(type * x.type, mult * x.mult)
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

  def initialize(schema)
    @schema = schema
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
    if this.elements.length == 0 then
      unit(comb)
    elsif this.elements.length == 1 then
      type_of(this.elements.first, klass, in_field, comb)
    else
      x = type_of(this.elements[0], klass, false, :*)
      1.upto(this.elements.length - 1) do |i|
        x *= type_of(this.elements[i], klass, false, :*)
      end
      return x
    end
  end

  def Call(this, klass, in_field, comb)
    if @memo[this]
      #puts "RETURNING MEMO: #{@memo[this]}"
      return @memo[this]
    end

    # if comb == :+ then
    #   @memo[this] = TM.new(VOID, ONE)
    # elsif comb == :* then
    #   @memo[this] = TM.new(VOID, ZERO)
    # else
    #   raise "Wrong comb: #{comb}"
    # end

    @memo[this] = unit(comb)

    x = type_of(this.rule, klass, in_field, comb)
    while x != @memo[this]
      @memo[this] = x
      x = type_of(this.rule, klass, in_field, comb)
    end
    return x
  end

  def Rule(this, klass, in_field, comb)
    type_of(this.arg, klass, in_field, comb)
  end

  def Alt(this, klass, in_field, comb)
    x = type_of(this.alts[0], klass, in_field, :+)
    1.upto(this.alts.length - 1) do |i|
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
    # TODO!!!
    #TM.new(Klass.new(DerefType.deref(@schema, @root_class, @ctx, this.path)), ONE)
    unit(comb) #TM.new(VOID, ZERO)
    #BOT
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
      next if fld.type.Primitive? || !fld.traversal 
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


if __FILE__ == $0 then
  if !ARGV[0] || !ARGV[1] || !ARGV[2] then
    puts "use typeof.rb <name>.grammar <name>.schema <rootclass>"
    exit!(1)
  end


  require 'core/system/load/load'
  require 'pp'

  g = Load::load(ARGV[0])
  s = Load::load(ARGV[1])
  start = ARGV[2]

  root_class = s.classes[start]

  to = TypeOf.new(s)

  test_class = s.classes["Regular"]
  puts to.type_of(g.start, test_class , true, :*)


  g.rules.each do |rule|
    puts "RULE #{rule.name}: #{to.type_of(rule, test_class, true, :*)}"
    rule.arg.alts.each do |alt|
      puts "\tALT: #{to.type_of(alt, test_class, true, :*)}"
      if alt.Sequence? then
        alt.elements.each do |elt|
          puts "\t\tELT: #{to.type_of(elt, test_class, true, :*)}"
        end
      end
    end
  end
end

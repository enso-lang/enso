
require 'core/system/load/load'
require 'core/schema/tools/copy'

class DeltaGrammar

  def initialize(factory)
    @factory = factory
    @memo = {}
    @rule_cache = {}
  end

  # TODO: pass in_field boolean to deal with field literals

  def self.delta(g)
    gs = Loader.load('grammar.schema')
    fact = ManagedData.new(gs)
    g2 = fact.Grammar
    rules = []
    g2.start = DeltaGrammar.new(fact).delta(g, rules)
    rules.each do |r|
      g2.rules << r
    end
    #g2.finalize
    return g2
  end

  def delta(this, rules)
    send(this.schema_class.name, this, rules)
  end

  def Grammar(this, rules)
    delta(this.start, rules)
  end

  def Rule(this, rules)
    if !@memo[this] then
      r = @factory.Rule(delta_name(this.name))
      rules << r
      @memo[this] = r # memo first, to prevent infinite loops
      darg = delta(this.arg, rules)
      if darg.schema_class.name == 'Alt' then
        r.arg = darg
      else
        r.arg = @factory.Alt([darg])
      end
    end
    @memo[this]
  end

  def Alt(this, rules)
    alts = this.alts.map do |alt|
      delta(alt, rules)
    end
    @factory.Alt(alts)
  end

  def Sequence(this, rules)
    elts = this.elements.map do |elt|
      delta(elt, rules)
    end
    @factory.Sequence(elts)
  end

  def Call(this, rules)
    @factory.Call(delta(this.rule, rules))
  end

  def Create(this, rules)
    @factory.Create(delta_name(this.name), delta(this.arg, rules))
  end

  def Field(this, rules)
    @factory.Field(this.name, delta(this.arg, rules))
  end


  def Value(this, rules)
    v = @factory.Value(this.kind)
    @factory.Alt([set_value(v), noop])
  end

  def Ref(this, rules)
    v = @factory.Value('sym')
    @factory.Alt([set_value(v), noop])
  end

  def Regular(this, rules)
    n = regular_name(this)
    if !@rule_cache[n] then
      r = @factory.Rule(regular_name(this))
      @rule_cache[n] = r
      darg = delta(this.arg, rules)
      alts = [delete_key(regular_arg_name(this)), modify(darg)]
      arg = @factory.Alt(alts)
      r.arg = arg
      rules << r
    end
    r = @rule_cache[n]
    @factory.Regular(@factory.Call(r), this.optional, this.many, this.sep)
  end

  def Code(this, rules)
    this
  end
  
  def Lit(this, rules)
    @factory.Lit(this.value)
  end
  
  def delta_name(name, id = nil)
    "D_#{name}#{id}"
  end

  def regular_name(reg)
    suffix = regular_suffix(reg)
    if reg.arg.schema_class.name == 'Call' then
      "D_#{reg.arg.rule.name}_#{suffix}"
    else
      "D_regular_#{reg._id}_#{suffix}"
    end
  end

  def field_name(field)
    if field.arg.schema_class.name == 'Call' then
      "D_#{field.name}_#{field.arg.rule.name}"
    elsif field.arg.schema_class.name == 'Regular' then
      "D_#{field.name}_#{regular_name(field.arg)}"
    else
      "D_#{field.name}_#{field._id}"
    end
  end

  def regular_suffix(reg)
    if reg.optional && !reg.many then
      'opt'
    elsif reg.optional && reg.many && !reg.sep then
      'iter_star'
    elsif !reg.optional && reg.many && !reg.sep then
      'iter_plus'
    elsif reg.optional && reg.many && reg.sep then
      "iter_star_sep_#{reg._id}"
    elsif !reg.optional && reg.many && reg.sep then
      "iter_plus_sep_#{reg._id}"
    end
  end


  def delete
    @factory.Sequence([@factory.Lit("(-)")])
  end

  def delete_key(name)
    v = @factory.Field('pos', @factory.Value('atom'))
    elts = [@factory.Lit("(-"), v , @factory.Lit(")")]
    @factory.Create("Delete_#{name}", @factory.Sequence(elts))
  end

  def modify(x)
    @factory.Sequence([x])
  end

  def noop
    @factory.Sequence([@factory.Lit("_")])
  end

  def set_value(x)
    @factory.Sequence([x])
  end

end

if __FILE__ == $0 then
  require 'core/grammar/render/layout'

  g = Loader.load('diff-point.grammar')
  gg = Loader.load('grammar.grammar')

  g2 = DeltaGrammar.delta(g)

  puts "Rendering"

  DisplayFormat.print(gg, g2)

end


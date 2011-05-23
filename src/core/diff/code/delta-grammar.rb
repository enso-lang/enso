
require 'core/system/load/load'
require 'core/schema/tools/copy'

class DeltaGrammar

  def initialize(g)
    @factory = g._graph_id
    @memo = {}
  end

  def self.delta(g)
    gs = Loader.load('grammar.schema')
    g2 = Copy.new(Factory.new(gs)).copy(g)
    rules = []
    g2.start = DeltaGrammar.new(g2).delta(g, rules)
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
      r = @factory.Rule(d(this.name))
      darg = delta(this.arg, rules)
      if darg.schema_class.name == 'Alt' then
        r.arg = darg
      else
        r.arg = @factory.Alt([darg])
      end
      rules << r
      @memo[this] = r
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
    if !@memo[this.rule] then
      @memo[this.rule] = delta(this.rule, rules)
    end
    @factory.Call(@memo[this.rule])
  end

  def Create(this, rules)
    @factory.Create(d(this.name), delta(this.arg, rules))
  end

  def Field(this, rules)
    r = @factory.Rule(d(this.name, this._id))
    d = delta(this.arg, rules)

    # this is too ugly, but needed for rendering
    # TODO: pass down extra info to resolve it down stream.
    if d.schema_class.name == 'Alt' then
      r.arg = d
    else
      if d.schema_class.name == 'Sequence' || d.schema_class.name == 'Create' then
        r.arg = @factory.Alt([d])        
      else
        r.arg = @factory.Alt([@factory.Sequence([d])])
      end
    end
    rules << r
    @factory.Field(this.name, @factory.Call(r))
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
    darg = delta(this.arg, rules)
    alts = [delete_key, add(this.arg), modify(darg)]
    arg = @factory.Alt(alts)
    r = @factory.Rule(iter_name(this))
    r.arg = arg
    rules << r
    @factory.Regular(@factory.Call(r), this.optional, this.many, this.sep)
  end

  def Code(this, rules)
    this
  end
  
  def Lit(this, rules)
    @factory.Lit(this.value)
  end
  
  def d(name, id = nil)
    "D_#{name}#{id}"
  end

  def iter_name(reg)
    "D_#{reg.arg.rule.name}_iter"
  end

  def delete
    @factory.Sequence([@factory.Lit("(-)")])
  end

  def delete_key
    v = @factory.Field('pos', @factory.Value('atom'))
    elts = [@factory.Lit("(-"), v , @factory.Lit(")")]
    @factory.Sequence(elts)
  end


  def add(x)
    elts = [@factory.Lit("(+"), x, @factory.Lit(")")]
    @factory.Sequence(elts)
  end

  def modify(x)
    @factory.Sequence([x])
  end

  def noop
    @factory.Sequence([@factory.Lit("...")])
  end

  def set_value(x)
    elts = [@factory.Lit("(!"), x, @factory.Lit(")")]
    @factory.Sequence(elts)
  end

end

if __FILE__ == $0 then
  require 'core/grammar/code/layout'

  g = Loader.load('schema.grammar')
  gg = Loader.load('grammar.grammar')

  g2 = DeltaGrammar.delta(g)

  DisplayFormat.print(gg, g2)

end


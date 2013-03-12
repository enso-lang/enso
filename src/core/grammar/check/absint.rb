
require 'core/grammar/check/domains'

class InferSchema
  include AbstractDomains

  def initialize
    @memo = {}
    @bottom = Schema.new
  end

  def eval(this, klass, field)
    send(this.schema_class.name, this, klass, field)
  end

  
  def Rule(this, klass, field)
    eval(this.arg, klass, field)
  end

  def Call(this, klass, field)
    if @memo[this]
      return @memo[this]
    end

    @memo[this] = @bottom
    x = eval(this.rule, klass, field)
    while x != @memo[this]
      @memo[this] = x
      x = eval(this.rule, klass, field)
    end
    return x
  end

  def Sequence(this, klass, field)
    if this.elements.length == 1 then
      eval(this.elements[0], klass, field)
    else
      this.elements.inject(Schema.new) do |cur, elt|
        cur * eval(elt, klass, nil)
      end
    end
  end

  def Alt(this, klass, field)
    # NB: alts is never empty
    x = eval(this.alts[0], klass, field)
    1.upto(this.alts.length - 1) do |i|
      x = x + eval(this.alts[i], klass, field)
    end
    return x
  end

  def Regular(this, klass, field)
    a = eval(this.arg, klass, field)
    if this.many? then
      if this.optional? then
        a.star
      else
        a.plus
      end
    else
      a.opt
    end
  end

  def Field(this, klass, field)
    s = Schema.new({klass.name => 
                     Fields.new({field.name => 
                                  Type.new(GrammarTypes::VOID, Multiplicity::ONE)})})
    s * eval(this.arg, klass, this)
  end

  def Create(this, klass, field)
    s = Schema.new({klass.name => 
                     Fields.new({field.name => 
                                  Type.new(GrammarTypes::Klass.new(this), 
                                           Multiplicity::ONE)})})
    s * eval(this.arg, this, nil)
  end    
end


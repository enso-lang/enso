
require 'core/system/library/cyclicmap'
require 'core/schema/code/factory'
require 'core/schema/tools/copy'

# in use
class CyclicMapNew < MemoBase
  def initialize()
    super()
  end
  def recurse(from)
    raise "shouldn't be nil" if from.nil?
    to = @memo[from]
    return to if to
    #puts "SENDING #{from.schema_class.name}"
    send(from.schema_class.name, from)
  end
  def register(from, to)
    @memo[from] = to
    yield to
    return to
  end
  # TODO: HACK!!!
  def registerUpdate(from, to)
    @memo[from] = to
    result = yield to
    @memo[from] = result
    return result
  end
end


class OptimizingGrammarFactory
  def initialize
    @factory = Factory::SchemaFactory.new(Load::load("grammar.schema"))
    @epsilon = @factory.Sequence()
  end

  def Grammar(*args)
    @factory.Grammar(*args)
  end

  def Rule(sub)
    @factory.Rule(sub) if sub 
  end

  def method_missing(*args)
    @factory.send(*args)
  end
end

class NullTest < CyclicMapNew
  def initialize
    super()
  end

  def recurse(obj)
    x = @memo[obj]
    return x unless x.nil?
    @memo[obj] = false  # TODO: wrong
    x = send(obj.schema_class.name, obj)
    @memo[obj] = x
    x
  end

  def Rule(from)
    registerUpdate(from, false) do |result|
      from.alts.each do |a|
        result = true if recurse(a)
      end
      result
    end
  end

  def Sequence(from)
    from.elements.each do |e|
      return false unless recurse(e)
    end
    true
  end

  def Field(from)
    recurse(from.arg)
  end

  def Create(from)
    recurse(from.arg)
  end
    
  def Epsilon(from)
    true
  end

  def Regular(from)
    from.optional
  end

  # symbol representing a 
  def Ref(from)
    false
  end

  def Value(from)
    false
  end 
  
  def Lit(from)
    false
  end
end

class RuleCopy < Copy
  def initialize(factory, grammar)
    super(factory)
    @grammar = grammar
    @indent = 0
  end
  def copy(source)
    @indent += 1
    #puts "#{' '*@indent}COPY #{source.to_s}"
    rule = super(source)
    if source.is_a?("Rule")
      @grammar.rules << rule
    end
    @indent -= 1
    return rule
  end
end

class Derivative < CyclicMapNew
  def initialize(token)
    super()
    @rule_num = 1
    @token = token
    @factory = OptimizingGrammarFactory::new    
    @nullable = NullTest.new()
  end

  def Grammar(from)
    @grammar = @factory.Grammar()
    @copier = RuleCopy.new(@factory, @grammar)
    r = recurse(from.start)
    if r
      @grammar.start = r 
      @grammar
    end
  end

  def Rule(from)
    @rule_num += 1
    registerUpdate(from, @factory.Rule(from.name + @rule_num.to_s)) do |to|
      arg = recurse(from.arg)
      if arg
        to.arg = arg
        @grammar.rules << to
        to
      else
        nil
      end
    end
  end

  def Alt(from)
    to = @factory.Alt()
    from.alts.each do |r|
      d = recurse(r)
      to.alts << d if d
    end
    to.alts.empty? ? nil : to
  end

  # Dc(p;q)  ==>  if p.nullable then  Dc(p);q | Dc(q)  else  Dc(p);q
  def Sequence(from)
    n = from.elements.size
    alt = @factory.Alt()
    for i in 0...n
      first = recurse(from.elements[i])
      if first
        p = @factory.Sequence()
        p.elements << first unless first.is_a?("Epsilon")
        for j in i+1...n
          p.elements << @copier.copy(from.elements[j])
        end
        alt.alts << p
      else
        break
      end
      break unless @nullable.recurse(from.elements[i])
    end
    alt.alts.empty? ? nil : alt
  end
  
  # nonterminal
  def Call(from)
    d = recurse(from.rule)
    d ? @factory.Call(d) : nil
  end

  def Epsilon(from)
    nil
  end

  # Dc(p*) ==>  if p.nullable then Dc(p)* else Dc(p);p*
  def Regular(from)
    d = recurse(from.arg)
    nil if d.nil?
    if !from.many
      return d
    else
      s = @factory.Sequence()
      s.elements << d
      s.elements << @factory.Regular(@copier.copy(from.arg), true, true)
      return s
    end
  end
  
  def Field(from)
    return recurse(from.arg)
  end

  def Create(from)
    return recurse(from.arg)
  end
  
  # Dc(p?)  ==>  if Dc(p) != error then Dc(p)? else empty
  def Opt(from)
    p = recurse(from.arg)
    p ? @factory.Opt(p) : @factory.Epsilon()
  end
  
  # identifier representing a remote object
  def Ref(from)
    return checkToken(Symbol)
  end

  def Value(from)
    if (@token.class.name == from.kind)
      return @factory.Epsilon()
    else
      return nil
    end
  end

  def Lit(from)
    if (@token == from.value)
      return @factory.Epsilon()
    else
      return nil
    end
  end
end


if __FILE__ == $0 then
  require 'core/system/load/load'
  require 'core/schema/tools/print'
 
  x = Load::load('grammar.grammar')

  x = Derivative.new("grammar").recurse(x)
  
  x = Derivative.new(:foo).recurse(x)
  x = Derivative.new("start").recurse(x)
  Print.new.recurse(x)
  x = Derivative.new(:bar).recurse(x)

  x = Derivative.new(:r1).recurse(x)
  x = Derivative.new(":=").recurse(x)
  x = Derivative.new("test").recurse(x)
  x = Derivative.new("*").recurse(x)
  
  Print.new.recurse(x)
    
end

  

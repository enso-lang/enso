

require 'core/system/load/load'
require 'core/grammar/code/layout'
require 'core/schema/code/factory'
require 'core/schema/tools/print'

class PEval
  SCHEMA = Loader.load('fexp.schema')

  def self.peval(prog)
    prog.main = PEval.new(prog).peval(prog.main, {})
    return prog
  end

  def initialize(prog)
    @prog = prog
    @fact = prog._graph_id
    @memo = {}
  end

  def peval(this, *args)
    send(this.schema_class.name, this, *args)
  end

  def Const(this, env)
    this
  end

  def Var(this, env)
    env[this.name] ? @fact.Const(env[this.name]) : this
  end

  def Prim(this, env)
    args = this.args.map { |a| peval(a, env) }
    if args.all? { |a| const?(a) } then
      vals = args.map { |a| a.value.value } 
      lift(vals.first.send(this.op, *vals[1..-1]))
    else
      @fact.Prim(this.op, args)
    end
  end

  def If(this, env)
    cond = peval(this.cond, env)
    if const?(cond) then
      b = cond.value.value
      return peval(this.body, env) if b == true;
      return peval(this.elseBody, env)
    end
    return @fact.If(cond, peval(this.body, env), peval(this.elseBody, env))
  end

  def Apply(this, env)
    args = this.args.map { |a| peval(a, env) }
    f = @prog.funcs.find { |f| f.name == this.name }
    dynf, dyna = [], []
    env = {}
    fn2 = this.name
    f.formals.each_with_index do |frm, i|
      if const?(args[i]) then
        v = args[i].value
        env[frm.name] = args[i].value
        fn2 += "_#{frm.name}_#{v.value}"
      else
        dynf << frm
        dyna << args[i]
      end
    end
    if dynf.empty? then
      peval(f.body, env) 
    elsif env.empty?
      @fact.Apply(this.name, args) 
    else
      if !@memo[fn2] then
        @memo[fn2] = true
        @prog.funcs << @fact.FuncDef(fn2, dynf, peval(f.body, env))
      end
      @fact.Apply(fn2, dyna)
    end
  end

  def const?(x)
    x.schema_class.name == "Const"
  end

  def lift(x)
    if x.is_a?(TrueClass) || x.is_a?(FalseClass) then
      @fact.Const(@fact.Bool(x))
    elsif x.is_a?(Integer) then
      @fact.Const(@fact.Int(x))
    else
      raise "Not supported yet"
    end
  end

end




if __FILE__ == $0 then
  g = Loader.load('fexp.grammar')
  s = Loader.load('fexp.schema')
  e = Loader.load('exp1.fexp')
  e2 = PEval.peval(e)
  DisplayFormat.print(g, e2)

  e = Loader.load('exp2.fexp')
  e2 = PEval.peval(e)
  DisplayFormat.print(g, e2)

  e = Loader.load('full-exp.fexp')
  e2 = PEval.peval(e)
  DisplayFormat.print(g, e2)

end

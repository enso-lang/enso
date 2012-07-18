require 'core/expr/code/eval'
require 'core/expr/code/lvalue'

module EvalCommand

  include EvalExpr, LValueExpr
  
  operation :eval

  #note that the closure stores variable states only,
  #not interpreter state
  #so calling a closure may produce different behavior
  #depending on where it is evaluated because the
  #interpreter may be different
  class Closure
    attr_accessor :env #this is a hack to allow self-recursion

    def initialize(body, formals, env, interp, args)
      @body = body
      @formals = formals
      @env = env.clone
      @interp = interp
      @args = args.clone
    end

    #params are the values used to call this function
    #args are used by the interpreter
    def call(*params)
      nenv = HashEnv.new
      @formals.zip(params).each do |f,v|
        nenv[f.name] = v
      end
      nenv.set_parent(@env)
      res = @body.eval(@args.merge(env: nenv))
      res
    end

    def to_s()
      "#<Closure(#{@formals.map{|f|f.name}.join(", ")}) {#{@body}}>"
    end
  end

  def eval_EWhile(cond, body)
    while cond.eval
      body.eval
    end
  end

  def eval_EFor(var, list, body, args={})
    nenv = HashEnv.new.set_parent(args[:env])
    list.eval.each do |val|
      nenv[var] = val
      body.eval(env: nenv)
    end
  end

  def eval_EIf(cond, body, body2)
    if cond.eval
      body.eval
    elsif !body2.nil?
      body2.eval
    end
  end

  def eval_EBlock(body)
    res = nil
    body.each do |c|
      res = c.eval
    end
    res
  end
  
  def eval_EFunDef(name, formals, body, args={})
    res = Closure.new(body, formals.map{|f|f.eval}, args[:env], self, args)
    res.env[name] = res #hack to enable self-recursion
    args[:env][name] = res
    res
  end
  
  def eval_ELambda(body, formals, args={})
    Proc.new { |*p| Closure.new(body, formals.map{|f|f.eval(args)}, args[:env], self, args).call(*p) }
  end
  
  def eval_Formal
    @this
  end

  def eval_EFunCall(fun, params, lambda, args={})
    if lambda.nil?
      fun.eval({:in_fc=>true}).call(*(params.map{|p|p.eval}))
    else
      p = lambda.eval(args)
      fun.eval({:in_fc=>true}).call(*(params.map{|p|p.eval}), &p) 
    end
  end

  def eval_EAssign(var, val)
    var.lvalue.value = val.eval
  end
end

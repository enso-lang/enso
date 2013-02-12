require 'core/expr/code/eval'
require 'core/expr/code/lvalue'

module EvalCommand

  include EvalExpr, LValueExpr
  
  include Dispatcher    
    
  def eval(obj)
    dispatch(:eval, obj.schema_class, obj)
  end

  #note that the closure stores variable states only,
  #not interpreter state
  #so calling a closure may produce different behavior
  #depending on where it is evaluated because the
  #interpreter may be different
  class Closure
    attr_accessor :env #this is a hack to allow self-recursion

    def initialize(body, formals, env, interp)
      @body = body
      @formals = formals
      @env = env.clone
      @interp = interp
    end

    #params are the values used to call this function
    #args are used by the interpreter
    def call(*params)
      #puts "CALL #{@formals} #{params}"
      nenv = HashEnv.new
      @formals.zip(params).each do |f,v|
        nenv[f.name] = v
      end
      nenv.set_parent(@env)
      @interp.dynamic_bind env: nenv do
        @interp.eval(@body)
      end
    end

    def to_s()
      "#<Closure(#{@formals.map{|f|f.name}.join(", ")}) {#{@body}}>"
    end
  end

  def eval_EWhile(cond, body)
    while eval(cond)
      eval(body)
    end
  end

  def eval_EFor(var, list, body)
    nenv = HashEnv.new.set_parent(@_.env)
    eval(list).each do |val|
      nenv[var] = val
      dynamic_bind env: nenv do
        eval(body)
      end
    end
  end

  def eval_EIf(cond, body, body2)
    if eval(cond)
      eval(body)
    elsif !body2.nil?
      eval(body2)
    end
  end

  def eval_EBlock(body)
    res = nil
    dynamic_bind in_fc: false do
      body.each do |c|
        res = eval(c)
      end
    end
    res
  end
  
  def eval_EFunDef(name, formals, body)
    res = Closure.new(body, formals, @_.env, self)
    res.env[name] = res #hack to enable self-recursion
    @_.env[name] = res
    res
  end
  
  def eval_ELambda(body, formals)
    #puts "LAMBDA #{formals} #{body}"
    Proc.new { |*p| Closure.new(body, formals, @_.env, self).call(*p) }
  end
  
  def eval_EFunCall(fun, params, lambda)
    dynamic_bind in_fc: true do 
      if lambda.nil?
        eval(fun).call(*(params.map{|p|eval(p)}))
      else
        p = eval(lambda)
        f = eval(fun)
        #puts "FunCall #{f}=#{f.class} #{p}"
        f.call(*(params.map{|p|eval(p)}), &p) 
      end
    end
  end

  def eval_EAssign(var, val)
    lvalue(var).value = eval(val)
  end
end

class EvalCommandC
  include EvalCommand
  def initialize
  end
end
require 'core/expr/code/eval'
require 'core/expr/code/lvalue'

module EvalCommand

  include EvalExpr, LValueExpr

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
      nenv = @env.clone
      @formals.zip(params).each do |f,v|
        nenv[f.name] = v
      end
      res = @interp.eval(@body, @args.merge({:env=>nenv}))
      res
    end

    def to_s()
      "#<Closure @body=#{@body} @formals=#{@formals.map{|f|f.name}} @env=#{@env}>"
    end
  end

  def eval_EWhile(cond, body, args={})
    res = nil
    while self.eval(cond, args)
      res = self.eval(body, args)
    end
    res
  end

  def eval_EFor(var, list, body, args={})
    list.each do |val|
      nenv = args[:env].merge({var=>val})
      self.eval(body, args.merge({:env=>nenv}))
    end
  end

  def eval_EIf(cond, body, body2, args={})
    if self.eval(cond, args)
      self.eval(body, args)
    elsif !body2.nil?
      self.eval(body2, args)
    end
  end

  def eval_ESwitch(name, args={})
  end

  def eval_EBlock(body, args={})
    res = nil
    body.each do |c|
      res = self.eval(c, args)
    end
    res
  end

  def eval_EFunDef(name, formals, body, args={})
    res = Closure.new(body, formals, args[:env], self, args)
    res.env[name] = res #hack to enable self-recursion
    args[:env][name] = res
    res
  end

  def eval_EAssign(var, val, args={})
    lvalue(var, args).value = self.eval(val, args)
  end

end

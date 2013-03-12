require 'core/expr/code/eval'
require 'core/expr/code/lvalue'
require 'core/semantics/code/interpreter'
require 'core/expr/code/env'

module Impl
  #note that the closure stores variable states only,
  #not interpreter state
  #so calling a closure may produce different behavior
  #depending on where it is evaluated because the
  #interpreter may be different
  class Closure
    attr_accessor :env #this is a hack to allow self-recursion

    def self.make_closure(body, formals, env, interp)
      Closure.new(body, formals, env, interp).method('call_closure')
    end

    def initialize(body, formals, env, interp)
      @body = body
      @formals = formals
      @env = env
      @interp = interp
    end

    #params are the values used to call this function
    #args are used by the interpreter
    def call_closure(*params)
      #puts "CALL #{@formals} #{params}"
      nv = {}
      @formals.each_with_index do |f,i|
        nv[f.name] = params[i]
      end
      nenv = Env::HashEnv.new(nv, @env)
      @interp.dynamic_bind env: nenv do
        @interp.eval(@body)
      end
    end

    def to_s()
      "#<Closure(#{@formals.map{|f|f.name}.join(", ")}) {#{@body}}>"
    end
  end

  module EvalCommand
  
    include Eval::EvalExpr
    include Lvalue::LValueExpr
    
    include Interpreter::Dispatcher    
      
    def eval(obj)
      dispatch(:eval, obj)
    end
    
    def eval_EWhile(cond, body)
      while eval(cond)
        eval(body)
      end
    end

    def eval_EFor(var, list, body)
      nenv = Env::HashEnv.new({var=>nil}, @D[:env])
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

    def eval_EBlock(fundefs, body)
      res = nil
      #fundefs are able to see each other but not any other variable created in the block
      defenv = Env::HashEnv.new({}, @D[:env])
#=begin
      dynamic_bind in_fc: false, env: defenv do
        fundefs.each do |c|
          eval(c)
        end
      end
#=end
      #rest of body can see fundefs
      env1 = Env::HashEnv.new({}, defenv)
      dynamic_bind in_fc: false, env: env1 do
        body.each do |c|
          res = eval(c)
        end
      end
      res
    end

    def eval_EFunDef(name, formals, body)
      @D[:env][name] = Impl::Closure.make_closure(body, formals, @D[:env], self)
      nil
    end

    def eval_ELambda(body, formals)
      #puts "LAMBDA #{formals} #{body}"
      Proc.new { |*p| Impl::Closure.make_closure(body, formals, @D[:env], self).call(*p) }
    end

    def eval_EFunCall(fun, params, lambda)
      m = dynamic_bind in_fc: true do
        eval(fun)
      end
      if lambda.nil?
        m.call(*(params.map{|p|eval(p)}))
      else
        b = eval(lambda)
        m.call(*(params.map{|p|eval(p)}), &b) 
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

  def self.eval(obj, args = {})
    interp = EvalCommandC.new
    if args.empty?
      interp.eval(obj)
    else
      interp.dynamic_bind args do
        interp.eval(obj)
      end
    end
  end
end

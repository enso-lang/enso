require 'core/expr/code/eval'
require 'core/expr/code/lvalue'

module Impl

  include EvalExpr, LValueExpr

  #note that the closure stores variable states only,
  #not interpreter state
  #so calling a closure may produce different behavior
  #depending on where it is evaluated because the
  #interpreter may be different
  class Closure
    def initialize(body, formals, env, interp, args)
      @body = body
      @formals = formals
      @env = env.clone
      @interp = interp
      @args = args
    end

    #params are the values used to call this function
    #args are used by the interpreter
    def call(*params)
      nenv = @env
      formals.zip(params).each do |f,v|
        nenv[f] = v
      end
      @interp.eval(@body, @args.merge({:env=>nenv}))
    end
  end

  def eval_EWhile(cond, body, args={})
    while eval(cond, args)
      eval(body, args)
    end
  end

  def eval_EFor(var, list, body, args={})
    list.each do |val|
      nenv = args[:env].merge({var=>val})
      eval(body, args.merge({:env=>nenv}))
    end
  end

  def eval_EIf(cond, body, body2, args={})
    if eval(cond, args)
      eval(body, args)
    elsif !body2.nil?
      eval(body2, args)
    end
  end

  def eval_EBlock(body, args={})
    body.each do |c|
      eval(c, args)
    end
  end

  def eval_EFunDef(formals, body, args={})
    Proc.new do |*params|
      nenv = args[:env].clone
      formals.map{|f|f.name}.zip(params).each do |k,v|
        nenv[k] = eval()
      end
    end

    instance_eval("lambda do |#{formals.map{|f|f.name}.join ','}|
      nenv = args[:env]
      formals.each { nenv[
      eval(body, args)
	  end")
  end

  def eval_EAssign(var, val, args={})
    lvalue(var, args).value = eval(val, args)
  end

  def eval_EImport(path, args={})
  end

  def eval_EVar(name, args={})
    args[:env][name]
  end



=begin
  EWhile ::= [EWhile] "while" cond:Expr body:Command
  EFor ::= [EFor] "for" var:str "=" list:Expr body:Command
  EIf ::= [EIf] "if" cond:Expr body:Command "else" else:Command
  ESwitch ::= [ESwitch] "switch" e:Expr
  EBlock ::= [EBlock] "{" body:Command* "}"
  EFunDef ::= [EFunDef] "def" name:str "(" params:{Param,","}* ")" body:Command
  EAssign ::= [EAssign] var:Expr "=" val:Expr
  EImport ::= [EImport] "require" path:str
=end
end

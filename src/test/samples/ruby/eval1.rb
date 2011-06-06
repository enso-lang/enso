require "core/system/load/load"
require "core/schema/tools/print"
require "core/grammar/code/layout"
require "core/system/library/schema"

grammar = Loader.load("rb.grammar")

#prog = Loader.load("eval.rb")
prog = Loader.load("konichiwa.rb")

#DisplayFormat.print(grammar, prog)

class Fun
  def initialize(name, argslist, body, env)
    @name = name
    @argslist = argslist
    @body = body
    @env = env
  end
  def execute(args)
    #bind args to argslist
    env = @env
    for i in 0..args.length-1
      env[@argslist[i].name] = args[i]
    end
    #execute
    return eval(@body, env)
  end
end

def eval(expr, env)
  if expr.is_a?(ManyField)
    res = nil
    expr.each do |c|
      res, env = eval(c, env)
    end
    return res, env
  else
    call = "eval_"+expr.schema_class.name
    return send(call, expr, env)
  end
end

def eval_RubyScript(prog, env)
  env["__functions"] = {}
  res = nil
  prog.commands.each do |c|
    res, env = eval(c, env)
  end
  return res, env
end

def eval_FunDef(fundef, env)
  res = Fun.new(fundef.fun, fundef.argslist, fundef.body, env)
  env["__functions"][fundef.fun] = res
  return res, env
end

def eval_FunCall(funcall, env)
  args = funcall.args.map{|x| v,e = eval(x, env); v}
  if env["__functions"].has_key?(funcall.fun) #if this is a function we defined
    return env["__functions"][funcall.fun].execute(args)
  else
    res = send(funcall.fun, args)
    return res, env
  end
end

def eval_AssgnStmt(assn, env)
  val, env1 = eval(rhs, env)
  env1[lhs] = val
  return val, env1
end

def eval_Req(req, env)
  require req.path
  return nil, env
end

def eval_EVarAcc(expr, env)
  return env[expr.name], env
end

def eval_EBPlus(expr, env)
  r1, env1 = eval(expr.e1, env)
  r2, env2 = eval(expr.e2, env1)
  return r1+r2, env2
end

def eval_EBEquals(expr, env)
  r1, env1 = eval(expr.e1, env)
  r2, env2 = eval(expr.e2, env1)
  return r1 == r2, env2
end

def eval_EBNEquals(expr, env)
  r1, env1 = eval(expr.e1, env)
  r2, env2 = eval(expr.e2, env1)
  return r1 != r2, env2
end

def eval_ETChoice(expr, env)
  guard, env1 = eval(expr.expr, env)
  if guard
    return eval(expr.e1, env1)
  else
    return eval(expr.e2, env1)
  end
end

def eval_EStrConst(val, env)
  return val.val, env
end

def eval_RetStmt(ret, env)
  return eval(ret.expr, env)
end

eval(prog, {})

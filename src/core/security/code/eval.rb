=begin

Eval function for expressions

=end

module ExprEval

  ###########################################
  # All the expression evaluation functions #
  ###########################################

  def eval(expr, env={})
    send("eval_#{expr.schema_class.name}", expr, env)
  end

  def eval_EBinOp(expr, env)
    e1 = eval(expr.e1, env)
    e2 = eval(expr.e2, env)
    return Kernel::eval("#{e1.inspect} #{expr.op} #{e2.inspect}")
  end

  def eval_EUnOp(expr, env)
    e = eval(expr.e, env)
    return Kernel::eval("#{expr.op} #{e.inspect}")
  end

  def eval_EField(expr, env)
    var = eval(expr.e, env)
    var.nil? ? nil : var.send(expr.fname)
  end

  def eval_EVar(expr, env)
    env[expr.name]
  end

  def eval_EListComp(expr, env)
    list = eval(expr.list, env)
    list.send(expr.op) do |l|
      eval(expr.expr, env.merge({expr.var => l}))
    end
  end

  def eval_EStrConst(expr, env)
    return expr.val
  end

  def eval_EIntConst(expr, env)
    return expr.val
  end

  def eval_EBoolConst(expr, env)
    return expr.val
  end

  def make_const(val, factory)
    if val.is_a?(String)
      factory.EStrConst(val)
    elsif val.is_a?(Integer)
      factory.EIntConst(val)
    elsif val.is_a?(TrueClass) or val.is_a?(FalseClass)
      factory.EBoolConst(val)
    else
      val
    end
  end

end
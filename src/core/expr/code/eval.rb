module EvalExpr

  def eval_ETernOp(op1, op2, e1, e2, e3, args=nil)
    self.eval(e1, args) ? self.eval(e2, args) : self.eval(e3, args)
  end

  def eval_EBinOp(op, e1, e2, args=nil)
    if op == "&"
      self.eval(e1, args) && self.eval(e2, args)
    elsif op == "|"
      self.eval(e1, args) || self.eval(e2, args)
    else
      self.eval(e1, args).send(op.to_s, self.eval(e2, args))
    end
  end

  def eval_EUnOp(op, e, args=nil)
    self.eval(e, args).send(op.to_s)
  end

  def eval_EVar(name, args=nil)
    env = args[:env]
    raise "ERROR: undefined variable #{name}" if !env.has_key?(name)
    env[name]
  end

  def eval_ESubscript(e, sub, args=nil)
    self.eval(e, args)[self.eval(sub, args)]
  end

  def eval_EConst(val, args=nil)
    val
  end

  def eval_ENil(args=nil)
    nil
  end

  def eval_EFunCall(fun, params, args={})
    nargs = args.clone
    nargs[:in_fc]=true
    self.eval(fun, nargs).call(*(params.map{|p|self.eval(p, args)}))
  end

  def eval_EField(e, fname, args=nil)
    if args[:in_fc]
      args[:in_fc] = false
      self.eval(e, args).method(fname.to_sym)
    else
      self.eval(e, args).send(fname)
    end
  end
end


module EvalExprIntern
  def eval_ETernOp(op1, op2, e1, e2, e3, args=nil)
    e1.eval ? e2.eval : e3.eval
  end

  def eval_EBinOp(op, e1, e2, args=nil)
    e1.eval.send(op.to_s, e2.eval)
  end

  def eval_EUnOp(op, e, args=nil)
    e.eval.send(op.to_s)
  end

  def eval_EField(e, fname, args=nil)
    var = e.eval
    var.nil? ? nil : var.send(fname)
  end

  def eval_EVar(name, args=nil)
    env = args[:env]
    raise "ERROR: undefined variable #{name}" if !env.has_key?(name)
    env[name]
  end

  def eval_EConst(val, args=nil)
    val
  end

end


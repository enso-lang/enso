module EvalExpr

  def eval_ETernOp(op1, op2, e1, e2, e3, args=nil)
    self.eval(e1, args) ? self.eval(e2, args) : self.eval(e3, args)
  end

  def eval_EBinOp(op, e1, e2, args=nil)
    r1 = self.eval(e1, args)
    r2 = self.eval(e2, args)
    r1.send(op, r2)
  end

  def eval_EUnOp(op, e, args=nil)
    self.eval(e, args).send(op)
  end

  def eval_EVar(name, args=nil)
    args[:env][name]
  end

  def eval_EConst(val, args=nil)
    val
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

  def eval_EBinOp(op, e1, e2, args=nil)
    Kernel::eval("#{e1.eval.inspect} #{op} #{e2.eval.inspect}")
  end

  def eval_EUnOp(op, e, args=nil)
    Kernel::eval("#{op} #{e.eval.inspect}")
  end

  def eval_EField(e, fname, args=nil)
    var = e.eval
    var.nil? ? nil : var.send(fname)
  end

  def eval_EVar(name, args=nil)
    args[:env][name]
  end

  def eval_EConst(val, args=nil)
    val
  end

end



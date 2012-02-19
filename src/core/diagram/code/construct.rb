
module EvalStencil
  def eval_Color(r, g, b, args={})
    args[:factory].Color(self.eval(r, args).round, self.eval(g, args).round, self.eval(b, args).round)
  end

  def eval_InstanceOf(base, class_name, args={})
    a = self.eval(base, args)
    a && Subclass?(a.schema_class, class_name)
  end
end

module Eval_Expr_Dynamic
  class Variable

  end

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

  def eval_EField(e, fname, args={})
    if args[:in_fc]
      args[:in_fc] = false
      self.eval(e, args).method(fname.to_sym)
    else
      r = self.eval(e, args)
      if args[:dynamic]
        r = r.dynamic_update
      end
      r[fname]
    end
  end

end

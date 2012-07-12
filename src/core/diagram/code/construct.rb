require 'core/expr/code/eval'

module EvalStencil
  include EvalExpr

  def eval_Color(r, g, b, args={})
    args[:factory].Color(r.eval(args).round, g.eval(args).round, b.eval(args).round)
  end

  def eval_InstanceOf(base, class_name, args={})
    a = base.eval(args)
    a && Subclass?(a.schema_class, class_name)
  end

  def eval_ETernOp(op1, op2, e1, e2, e3, args=nil)
    if !args[:dynamic]
      super
    else
      v = e1.eval(args)
      fail "NON_DYNAMIC #{v}" if !v.is_a?(Variable)
      a = e2.eval(args)
      b = e3.eval(args)
      v.test(a, b)
    end
  end

  def eval_EBinOp(op, e1, e2, args=nil)
    if !args[:dynamic]
      super
    else
      r1 = e1.eval(args)
      r1 = Variable.new("gen", r1) if r1 && !r1.is_a?(Variable)
      r2 = e2.eval(args)
      r2 = Variable.new("gen", r2) if r2 && !r2.is_a?(Variable)
      r1.send(op.to_s, r2)
    end
  end

  def eval_EUnOp(op, e, args=nil)
    if !args[:dynamic]
      super
    else
      r1 = e1.eval(args)
      r1 = Variable.new("gen", r1) if r1 && !r1.is_a?(Variable)
      r1.send(op.to_s)
    end
  end

  def eval_EFunCall(fun, params, args={})
    nargs = args.clone
    nargs[:in_fc]=true
    fun.eval(nargs).call(*(params.map{|p|p.eval(args)}))
  end

  def eval_EField(e, fname, args={})
    if args[:in_fc]
      args[:in_fc] = false
      e.eval(args).method(fname.to_sym)
    else
      r = e.eval(args)
      if args[:dynamic]
        if r.is_a? Variable
          r = r.value.dynamic_update
        else
          r = r.dynamic_update
        end
      end
      return r._id if fname == "_id"
      r[fname]
    end
  end

end

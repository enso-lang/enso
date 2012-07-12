module EvalExpr

  def eval_EBinOp(op, e1, e2, args={})
    e1.eval(args).send(op.to_s, e2.eval(args))
  end

  def eval_EUnOp(op, e, args=nil)
    e.eval(args).send(op.to_s)
  end

  def eval_EFunCall(fun, params, args={})
    nargs = args.clone
    nargs[:in_fc]=true
    fun.eval(nargs).call(*(params.map{|p|p.eval(args)}))
  end

  def eval_EField(e, fname, args=nil)
    if args[:in_fc]
      args[:in_fc] = false
      e.eval(args).method(fname.to_sym)
    else
      e.eval(args).send(fname)
    end
  end

  def eval_EVar(name, args=nil)
    env = args[:env]
    puts "ERROR: undefined variable #{name}" if !env.has_key?(name)
    env[name]
  end

  def eval_EConst(val, args=nil)
    val
  end

end

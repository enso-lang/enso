require 'core/schema/code/factory'

module EvalExpr
  
  operation :eval

  def eval_ETernOp(op1, op2, e1, e2, e3)
    e1.eval ? e2.eval : e3.eval
  end

  def eval_EBinOp(op, e1, e2)
    if op == "&"
      e1.eval && e2.eval
    elsif op == "|"
      e1.eval || e2.eval
    else
      e1.eval.send(op.to_s, e2.eval)
    end
  end

  def eval_EUnOp(op, e)
    e.eval.send(op.to_s)
  end

  def eval_EVar(name, env)
    raise "ERROR: undefined variable #{name}" unless env.has_key?(name)
    env[name]
  end

  def eval_ESubscript(e, sub)
    e.eval[sub.eval]
  end

  def eval_EConst(val)
    val
  end

  def eval_ENil
    nil
  end

  def eval_EFunCall(fun, params)
    fun.eval(in_fc: true).call(*(params.map{|p|p.eval}))
  end

  def eval_EList(elems)
    r = ManagedData::List.new(nil, nil)
    elems.each do |elem|
      #puts "ELEM #{elem}=#{elem.eval}"
      r << elem.eval
    end
    r
  end

  def eval_EField(e, fname, in_fc)
    if in_fc
      e.eval(in_fc: false).method(fname.to_sym)
    else
      e.eval.send(fname)
    end
  end
end

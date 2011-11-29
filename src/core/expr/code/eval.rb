
module EvalExpr
  def eval1_EBinOp(op, e1, e2, *args)
    Kernel::eval("#{e1.inspect} #{op} #{e2.inspect}")
  end

  def eval1_EUnOp(op, e, *args)
    Kernel::eval("#{op} #{e.inspect}")
  end

  def eval1_EStrConst(val, *args)
    val
  end

  def eval1_EIntConst(val, *args)
    val
  end

  def eval1_EBoolConst(val, *args)
    val
  end
end


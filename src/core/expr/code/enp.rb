
module EvalExpr
  def enp_?(*args)
    eval
  end

  def eval_EBinOp(*args)
    Kernel::eval("#{e1.eval(*args).inspect} #{op} #{e2.eval(*args).inspect}")
  end

  def eval_EUnOp(*args)
    Kernel::eval("#{op} #{e.eval(*args).inspect}")
  end

  def eval_EStrConst(*args)
    val
  end

  def eval_EIntConst(*args)
    val
  end

  def eval_EBoolConst(*args)
    val
  end
end


module RenderExpr

  def render_EBinOp(op, e1, e2, *args)
    "#{e1} #{op} #{e2}"
  end

  def render_EUnOp(op, e, *args)
    "#{op} #{e}"
  end

  def render_EStrConst(val, *args)
    val
  end

  def render_EIntConst(val, *args)
    val
  end

  def render_EBoolConst(val, *args)
    val
  end

end


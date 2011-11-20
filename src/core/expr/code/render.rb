
module RenderExpr
  def render_EBinOp(*args)
    "#{e1.render(*args)} #{op} #{e2.render(*args)}"
  end

  def render_EUnOp(*args)
    "#{op} #{e.render(*args)}"
  end

  def render_EStrConst(*args)
    val
  end

  def render_EIntConst(*args)
    val
  end

  def render_EBoolConst(*args)
    val
  end
end



module RenderExpr
  
  operation :render

  def render_EBinOp(op, e1, e2)
    "#{e1.render} #{op} #{e2.render}"
  end

  def render_EUnOp(op, e)
    "#{op} #{e.eval.inspect}"
  end

  def render_EField(e, fname)
    "#{e.render}.#{fname}"
  end

  def render_EVar(name)
    "#{name}"
  end

  def render_EConst(val)
    "#{val}"
  end
end

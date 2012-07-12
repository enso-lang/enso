
module RenderExpr

  def render_EBinOp(op, e1, e2, args=nil)
    "#{e1.render(args)} #{op} #{e2.render(args)}"
  end

  def render_EUnOp(op, e, args=nil)
    "#{op} #{e.eval(args).inspect}"
  end

  def render_EField(e, fname, args=nil)
    "#{e.render(args)}.#{fname}"
  end

  def render_EVar(name, args=nil)
    "#{name}"
  end

  def render_EConst(val, args=nil)
    "#{val}"
  end
end


module RenderExpr

  def render_EBinOp(op, e1, e2, args=nil)
    "#{self.render(e1, args)} #{op} #{self.render(e2, args)}"
  end

  def render_EUnOp(op, e, args=nil)
    "#{op} #{self.eval(e, args).inspect}"
  end

  def render_EField(e, fname, args=nil)
    "#{self.render(e, args)}.#{fname}"
  end

  def render_EVar(name, args=nil)
    "#{name}"
  end

  def render_EConst(val, args=nil)
    "#{val}"
  end
end

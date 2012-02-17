
module EvalStencil
  def eval_Color(r, g, b, args={})
    args[:factory].Color(self.eval(r, args).round, self.eval(g, args).round, self.eval(b, args).round)
  end

  def eval_InstanceOf(base, class_name, args={})
    a = self.eval(base, args)
    a && Subclass?(a.schema_class, class_name)
  end
end

module BindExpr

  def bind_EVar(name, args=nil)
    env = args[:env]
    if env.keys.include? name
      BindExpr.make_const(env[name], args[:factory])
    else
      args[:self]
    end
  end

  def bind_?(op, e1, e2, args=nil)
    args[:self]
  end

  def self.make_const(val, factory)
    if val.is_a?(String)
      factory.EStrConst(val)
    elsif val.is_a?(Integer)
      factory.EIntConst(val)
    elsif val.is_a?(TrueClass) or val.is_a?(FalseClass)
      factory.EBoolConst(val)
    else
      val
    end
  end
end

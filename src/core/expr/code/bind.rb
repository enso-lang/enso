module BindExpr

  include Interpreter::Dispatcher    
    
  def bind(obj)
    dispatch_obj(:bind, obj)
  end

 # args
  def bind_EVar(obj)
    env = @D[:env]
    if env.keys.include?(obj.name)
      BindExpr.make_const(env[obj.name], @D[:factory])
    else
      obj
    end
  end

  def bind_?(obj)
    obj
  end

end

class BindExprC
  include BindExpr
end
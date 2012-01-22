module FoldExpr

  def fold_EBinOp(op, e1, e2, args=nil)
    Kernel::eval("#{self.eval(e1, args)} #{op} #{self.eval(e2, args)}")
  end

  def fold_EUnOp(op, e, args=nil)


    expr.e = bind!(expr.e, env)
    if expr.e.EConst?
      return make_const(eval(expr, env), expr.factory)
    elsif expr.e.EUnOp? and (expr.e.op == 'not' or expr.e.op == '!') #dbl negation
      return expr.e.e
    end

    Kernel::eval("#{op} #{self.eval(e, args).inspect}")
  end

  def fold_EField(e, fname, args=nil)
    var = self.eval(e, args)
    var.nil? ? nil : var.send(fname)
  end

  def fold_EVar(name, args=nil)
    args[:env][name]
  end

  def fold_EConst(val, args=nil)
    val
  end

  def fold_EFunCall(fun, params, args=nil)
    self.eval(fun, args).call(*(params.map{|p|self.eval(p, args)}))
  end

  def fold_EField(e, fname, args=nil)
    self.eval(e, args).send(fname)
  end
end



module ExprBind

  include ExprEval

  # substitute all instances of variables in env with their value
  # also does reduction while binding

  def bind!(expr, env={})
    send("bind_#{expr.schema_class.name}!", expr, env)
  end

  def bind_EBinOp!(expr, env)
    expr.e1 = bind!(expr.e1, env)
    expr.e2 = bind!(expr.e2, env)
    if expr.e1.EConst? and expr.e2.EConst?
      return make_const(eval(expr, env), expr.factory)
    elsif expr.op == 'or' or expr.op == '||'
      if expr.e1.EBoolConst? and expr.e1.val==true
        return make_const(true, expr.factory)
      elsif expr.e1.EBoolConst? and expr.e1.val==false
        return expr.e2
      elsif expr.e2.EBoolConst? and expr.e2.val==true
        return make_const(true, expr.factory)
      elsif expr.e2.EBoolConst? and expr.e2.val==false
        return expr.e1
      end
    elsif expr.op == 'and' or expr.op == '&&'
      if expr.e1.EBoolConst? and expr.e1.val==true
        return expr.e2
      elsif expr.e1.EBoolConst? and expr.e1.val==false
        return make_const(false, expr.factory)
      elsif expr.e2.EBoolConst? and expr.e2.val==true
        return expr.e1
      elsif expr.e2.EBoolConst? and expr.e2.val==false
        return make_const(false, expr.factory)
      end
    end
    if expr.e1.schema_class.name=="EVar" and expr.e1.name=="*" and (expr.op == 'or' or expr.op == '||' or expr.op == 'and' or expr.op == '&&')
      return expr.e2
    elsif expr.e2.schema_class.name=="EVar" and expr.e2.name=="*" and (expr.op == 'or' or expr.op == '||' or expr.op == 'and' or expr.op == '&&')
      return expr.e1
    end
    expr
  end

  def bind_EUnOp!(expr, env)
    expr.e = bind!(expr.e, env)
    if expr.e.EConst?
      return make_const(eval(expr, env), expr.factory)
    elsif expr.e.EUnOp? and (expr.e.op == 'not' or expr.e.op == '!') #dbl negation
      return expr.e.e
    end
    expr
  end

  def bind_EVar!(expr, env)
    if expr.name=="*" or expr.name.start_with?('@')
      expr
    else
      if env.keys.include?(expr.name)
        val = eval_EVar(expr, env)
        if val.EStrConst? and val.val.start_with?('@')
          expr.name = val.val
          expr
        else
          make_const(val, expr.factory)
        end
      else
        #TODO: try and figure out relationhip btw vars here
        expr.name = "*"
        expr
      end
    end
  end

  def bind_EField!(expr, env)
    expr.e = bind!(expr.e, env)
    if expr.e.schema_class.name=="EVar" and expr.e.name=="*"
      return expr.e
    end
    expr
  end

  def bind_EListComp!(expr, env)
    bind!(expr.list, env)
    #remove vars from env which are now outside their scope due to expr.var
    bind!(expr.expr, env.reject {| key, value | key == expr.var })
    expr
  end

  def bind_EStrConst!(expr, env)
    expr
  end

  def bind_EIntConst!(expr, env)
    expr
  end

  def bind_EBoolConst!(expr, env)
    expr
  end

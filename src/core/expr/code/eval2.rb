

module ExprEval
  class ETernOp
    attr_reader :e1, :e2, :e3
    def eval(env)
      e1.eval(env) ? e2.eval(env) : e3.eval(env)
    end
  end

  class EBinOp
    attr_reader :op, :e1, :e2
    def eval(env)
      case op
      when '&' then e1.eval(env) && e2.eval(env)
      when '|' then e1.eval(env) || e2.eval(env)
      else
        e1.eval(env).send(op, e2.eval(env))
      end
    end
  end

  class EUnOp
    attr_reader :e, :op
    def eval(env)
      e.eval(env).send(op)
    end
  end

  class EVar
    attr_reader :name
    def eval(env)
      raise "Undefined variable #{name}" if !env.has_key?(name)
      env[name]
    end
  end

  class ESubscript
    attr_reader :e, :sub
    def eval(env)
      e.eval(env)[sub.eval(env)]
    end
  end

  class EConst
    attr_reader :val
    def eval(env)
      val
    end
  end

  class EStrConst < EConst; end
  class EIntConst < EConst; end
  class EBoolConst < EConst; end
  class ERealConst < EConst; end

  class ENil
    def eval(env)
      nil
    end
  end

  class EFunCall
    attr_reader :fun, :params
    def eval(env)
      clos = fun.eval(env)
      args = params.map { |p| p.eval(env) }
      clos.call(*args)
    end
  end

  class EField
    attr_reader :e, :fname
    def eval(env)
      e.eval(env).send(fname)
    end
  end

end

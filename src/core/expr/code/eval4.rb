
require 'core/semantics/factories/combinators'

class Eval
  include Factory

  def ETernOp(sup)
    Class.new(sup) do
      attr_reader :e1, :e2, :e3
      def eval(env)
        e1.eval(env) ? e2.eval(env) : e3.eval(env)
      end
    end
  end

  def EBinOp(sup)
    Class.new(sup) do
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
  end

  def EUnOp(sup)
    Class.new(sup) do
      attr_reader :e, :op
      def eval(env)
        e.eval(env).send(op)
      end
    end
  end

  def EVar(sup)
    Class.new(sup) do
      attr_reader :name
      def eval(env)
        raise "Undefined variable #{name}" if !env.has_key?(name)
        env[name]
      end
    end
  end

  def ESubscript(sup)
    Class.new(sup) do
      attr_reader :e, :sub
      def eval(env)
        e.eval(env)[sub.eval(env)]
      end
    end
  end

  def EConst(sup)
    Class.new(sup) do
      attr_reader :val
      def eval(env)
        val
      end
    end
  end

  def EStrConst(sup); EConst(sup) end
  def EIntConst(sup); EConst(sup) end
  def EBoolConst(sup); EConst(sup) end
  def ERealConst(sup); EConst(sup) end

  def ENil(sup)
    Class.new(sup) do
      def eval(env)
        nil
      end
    end
  end

  def EFunCall(sup)
    Class.new(sup) do
      attr_reader :fun, :params
      def eval(env)
        clos = fun.eval(env)
        args = params.map { |p| p.eval(env) }
        clos.call(*args)
      end
    end
  end

  def EField(sup)
    Class.new(sup) do
      attr_reader :e, :fname
      def eval(env)
        e.eval(env).send(fname)
      end
    end
  end
  
end

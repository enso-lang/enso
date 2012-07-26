
require 'core/semantics/factories/test/exprs'
require 'core/semantics/factories/combinators'


class Var
  attr_reader :name
  def initialize(name)
    @name = name
  end
end

class Puts
  attr_reader :arg
  def initialize(arg)
    @arg = arg
  end
end

class EnvEval
  include Factory

  def Var(sup)
    Class.new(sup) do
      def eval(env)
        env[name]
      end
    end
  end
end

class IOEval
  include Factory
  def Puts(sup)
    Class.new(sup) do 
      def eval(out, env)
        x = arg.eval(env)
        out << "RESULT #{x}\n"
        0
      end
    end
  end
end


if __FILE__ == $0 then
  # (1 + x) + (5 + (1 + x)) with x = 100 --> 207
  ex1 = Add.new(Const.new(1), Var.new(:x))
  ex2 = Add.new(Const.new(5), ex1)
  ex3 = Add.new(ex1, ex2)

  puts "### Eval + Env"
  eval = FFold.new(Morph.new(EnvEval.new, Eval.new, :eval, [], :env)).fold(ex3)

  puts eval.eval(x: 100)



  puts "### Eval + Env + IO"

  # (1 + x) + (puts(5) + (1 + x)) with x = 100 --> 202
  ex1 = Add.new(Const.new(1), Var.new(:x))
  ex2 = Add.new(Puts.new(Const.new(5)), ex1)
  ex4 = Add.new(ex1, ex2)

  eval = FFold.new(Morph.new(IOEval.new, 
                             Morph.new(EnvEval.new, Eval.new, :eval, [], :env),
                             :eval, [:env], :out)).fold(ex4)



  puts eval.eval($stdout, {x: 100})

end

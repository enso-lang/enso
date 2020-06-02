
require 'core/semantics/factories/combinators'
require 'core/semantics/factories/obj-fold'

class Expr
end

class Add < Expr
  attr_reader :lhs, :rhs
  def initialize(lhs, rhs)
    super()
    @lhs = lhs
    @rhs = rhs
  end
end

class Const < Expr
  attr_reader :value
  def initialize(value)
    super()
    @value = value
  end
end

class Eval
  include Factory

  def Add(sup)
    Class.new(sup) do 
      def eval
        lhs.eval + rhs.eval
      end
    end
  end

  def Const(sup)
    Class.new(sup) do 
      def eval
        value
      end
    end
  end
end

class Render
  include Factory

  def Add(sup)
    Class.new(sup) do
      def render
        "#{lhs.render} + #{rhs.render}"
      end
    end
  end

  def Const(sup)
    Class.new(sup) do
      def render
        value.to_s
      end
    end
  end
end


if __FILE__ == $0 then
  Ex1 = Add.new(Const.new(1), Const.new(2))
  Ex2 = Add.new(Const.new(5), Ex1)

  puts "### Eval"
  EvalEx1 = FFold.new(Eval.new).fold(Ex1)

  puts EvalEx1.eval
  
  puts "### Render"
  RenderEx1 = FFold.new(Render.new).fold(Ex1)
  
  puts RenderEx1.render
end

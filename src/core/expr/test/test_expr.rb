require 'test/unit'

require 'core/system/load/load'
require 'core/expr/code/eval'

class ExprTest < Test::Unit::TestCase

  def test_base
    interp = Interpreter(EvalExpr)

    ex0 = Loader.load("expr1.expr")
    assert_equal(6, interp.eval(ex0))
  end

  def test_internal
    interp = Interpreter(InternalVisitor("eval", EvalExprIntern))

    ex0 = Loader.load("expr1.expr")
    assert_equal(6, interp.visit(ex0))
  end

  class A
    attr_reader :f1
    def initialize(f1); @f1=f1; end
  end

  def test_funct
    interp = Interpreter(EvalExpr)

    ex0 = Loader.load("expr2.expr")
    a = A.new(2)
    x = 12
    assert_equal(12, interp.eval(ex0, :env=>{'a'=>a, 'x'=>x}))
  end

end

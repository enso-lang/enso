require 'test/unit'

require 'core/system/load/load'
require 'core/expr/code/eval'
require 'core/semantics/code/interpreter'

class ExprTest < Test::Unit::TestCase

  def test_base
    interp = EvalExprC.new

    ex0 = Loader.load("expr1.expr")
    assert_equal(6, interp.eval(ex0))
  end

  class A
    attr_reader :f1
    def initialize(f1); @f1=f1; end
  end

  def test_funct
    interp = EvalExprC.new

    ex0 = Loader.load("expr2.expr")
    a = A.new(2)
    x = 12
    interp.dynamic_bind env: {'a'=>a, 'x'=>x} do 
      assert_equal(12, interp.eval(ex0))
    end
  end

end

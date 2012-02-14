require 'test/unit'

require 'core/system/load/load'
require 'core/expr/code/impl'

class CommandTest < Test::Unit::TestCase

  def test_impl1
    #test while loops, assignments
    interp = Interpreter(EvalCommand)
    impl1 = Loader.load("test1.impl")

    assert_equal(20, interp.eval(impl1, :env=>{}))
  end

  def test_impl2
    #test fun def and calls, external environment
    interp = Interpreter(EvalCommand)
    impl2 = Loader.load("test2.impl")

    assert_equal(42, interp.eval(impl2, :env=>{'x'=>22}))
  end

  def test_fib
    #test fun def and calls, if, recursion
    interp = Interpreter(EvalCommand)
    fib = Loader.load("fibo.impl")

    assert_equal(34, interp.eval(fib, :env=>{'f'=>10}))
  end
end

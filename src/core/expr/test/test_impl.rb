require 'test/unit'

require 'core/system/load/load'
require 'core/expr/code/impl'

class CommandTest < Test::Unit::TestCase

  def test_load_print
    obj = Loader.load("test1.impl")
    g = Loader.load("impl.grammar")
    str = ""
    DisplayFormat.print(g, obj, 80, str)
    puts str
=begin
    assert_equal(str.squeeze(" "), "{
    x = 0 
    i = 0 
    j = 0 
    while i < 4 { j = 0 while j < 5 { x = x + 1 j = j + 1 } i = i + 1 } 
    return x".squeeze(" "))
=end
  end

  def test_impl1
    #test while loops, assignments
    interp = Interpreter(EvalCommand)
    impl1 = Loader.load("test1.impl")

    assert_equal(20, interp.eval(impl1, env: {}))
  end

  def test_impl2
    #test fun def and calls, external environment
    interp = Interpreter(EvalCommand)
    impl2 = Loader.load("test2.impl")

    assert_equal(42, interp.eval(impl2, env: {'x'=>22}))
  end

  def test_fib
    #test fun def and calls, if, recursion
    interp = Interpreter(EvalCommand)
    fib = Loader.load("fibo.impl")

    assert_equal(34, interp.eval(fib, env: {'f'=>10}))
  end
  
  def test_piggyback
    #test the ability to piggyback on top of ruby's libraries, incl procs
    interp = Interpreter(EvalCommand)
    fib = Loader.load("ruby_piggyback.impl")

    assert_equal([2,3], interp.eval(fib, env: {'s'=>[1,2,3]}))
  end
end

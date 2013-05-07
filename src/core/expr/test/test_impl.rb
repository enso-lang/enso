require 'test/unit'

require 'core/system/load/load'
require 'core/expr/code/impl'

class CommandTest < Test::Unit::TestCase

  def test_load_print
    obj = Load::load("test1.impl")
    g = Load::load("impl.grammar")
    str = ""
#    Layout::DisplayFormat.print(g, obj, str)
#    puts str
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
    assert_equal(20, Impl.eval(Load::load("test1.impl")))
  end

  def test_impl2
    #test fun def and calls, external environment
    impl2 = Load::load("test2.impl")
    assert_equal(57, Impl.eval(impl2, env: {'x'=>22, 'lst'=>[1,2,3,4,5]}))
  end

  def test_fib
    #test fun def and calls, if, recursion
    interp = Impl::EvalCommandC.new
    fib = Load::load("fibo.impl")

    interp.dynamic_bind env: {'f'=>10} do
      assert_equal(34, interp.eval(fib))
    end
  end
  
  def test_piggyback
    #test the ability to piggyback on top of ruby's libraries, incl procs
    interp = Impl::EvalCommandC.new
    piggy = Load::load("ruby_piggyback.impl")

    interp.dynamic_bind env: {'s'=>[1,2,3]} do
      assert_equal([2,3], interp.eval(piggy))
    end
  end
end

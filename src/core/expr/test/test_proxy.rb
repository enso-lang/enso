require 'test/unit'

require 'core/system/load/load'
require 'core/expr/code/eval'
require 'core/expr/taint/proxy'

class ProxyTest < Test::Unit::TestCase

  def test_basic
    five = Proxy::Proxy.new(5, "file5", 5)
    ten = Proxy::Proxy.new(10, "file10", 10)

    b = 5+five
    assert_equal(10, b)
    assert_equal(1, b._sources.size)

    c = b * ten
    assert_equal(100, c)
    assert_equal(2, c._sources.size)
    env = {} #make a dummy env where five=>50 and ten=>100
    env[c._sources.key(["file5", 5])] = 50
    env[c._sources.key(["file10", 10])] = 100
    assert_equal(5500, Eval.eval(c._tree, env:env))
  end

  def test_expr
    ex0 = Load::load("expr1.expr")
    a = Proxy::Proxy.new(ex0)
    res = Eval.eval(a)
    assert_equal(6, res)
    assert_equal(3, res._sources.size)
    #Print.print res._tree
    env = {}
    res._sources.each do |k,v|
      if v[1].to_s == "root.e1.e1.val"
        env[k] = 111
      elsif v[1].to_s == "root.e1.e2.val"
        env[k] = 222
      elsif v[1].to_s == "root.e2.val"
        env[k] = 333
      end
    end
    assert_equal(666, Eval.eval(res._tree, env:env))
  end

  def test_impl1
    i = Load::load("test1.impl")
    impl1 = Proxy::Proxy.new(i)
    res = Impl.eval(impl1)
    assert_equal(20, res)
    assert_equal(2, res._sources.size)
  end
end

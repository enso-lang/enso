require 'test/unit'

require 'core/system/load/load'
require 'core/expr/code/eval'
require 'core/expr/code/render'
require 'core/expr/code/vars'
require 'core/expr/code/wrap'

class ExprTest < Test::Unit::TestCase

  def test_add_actions
    #load an expression and display it
    ex0 = Loader.load("my-expr.expr")

    #add actions to the expression
    f = Factory.new(Loader.load("expr.schema"))
    f.add_interp(EvalExpr)
    assert_equal(Copy(f,ex0).eval, 6)

    f.add_interp(RenderExpr)
    assert_equal(Copy(f,ex0).render, "1 + 2 + 3")
  end

  def test_add_types
    s = union(Loader.load('expr-vars.schema'), Loader.load('expr.schema'))
    g = union(Loader.load('expr-vars.grammar'), Loader.load('expr.grammar'))
    ex1 = Loader.load_with_models("my-expr-vars.expr", g, s)

    fv = Factory.new(s)
    fv.add_interp(EvalExpr)
    fv.add_interp(RenderExpr)
    fv.add_interp(Vars)

    assert_equal(Copy(fv, ex1).eval({'a'=>5}), 22)
    assert_equal(Copy(fv, ex1).render, "a + 17")
  end

  def test_generic
    #load an expression and display it
    ex0 = Loader.load("my-expr.expr")

    #add actions to the expression
    f = Factory.new(Loader.load("expr.schema"))
    f.add_interp(RenderExpr)
    f.add_interp(Wrap)
    Print.print Copy(f,ex0).wrap
    assert_equal(Copy(f,ex0).wrap, "1 + 2 + 3")
  end
end

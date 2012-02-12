require 'test/unit'

require 'core/system/load/load'
require 'core/semantics/code/compose'
require 'core/semantics/code/interpreter'
require 'core/expr/code/eval'
require 'core/expr/code/render'

class ExprTest < Test::Unit::TestCase

  def test_compose
    op = "eval"
    interp = Interpreter(Compose('eval', [EvalExpr]) do |fields, type, args={}|
      puts "[DEBUG] At #{type}.#{op}: #{fields} args=(#{args})"
      gets
      send(op, fields, type, args)
    end)
    ex0 = Loader.load("my-expr.expr")
    interp.debug(ex0)
  end

end

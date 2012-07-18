
require 'test/unit'

require 'core/system/load/load'
require 'test/samples/exp/eval.rb'
require 'core/semantics/code/interpreter'


class ExpTest < Test::Unit::TestCase

  def test_base
    interp = Interpreter(Eval)

    ex0 = Loader.load("sample.exp")
    assert_equal(33, interp.eval(ex0))
  end

end

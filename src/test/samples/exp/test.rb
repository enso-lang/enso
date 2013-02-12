
require 'test/unit'

require 'core/system/load/load'
require 'test/samples/exp/eval.rb'
require 'core/semantics/code/interpreter'


class ExpTest < Test::Unit::TestCase

  def test_base
    interp = Eval.new

    e = Loader.load("sample.exp")
    puts "--LOADING SIMPLE EXPRESSION---"
    e = Loader.load("sample.exp")

    puts "*EXP #{e}"
    puts "*Children #{e.subexpressions}"
    a = e.subexpressions[0]
    puts "*BINDING #{e.body.body.left.binding}"
    puts "*PARENT #{a.parent}"

    assert_equal(10, interp.eval(e))
    
  end

end

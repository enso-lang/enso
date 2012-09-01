
require 'test/unit'

require 'core/system/load/load'
require 'test/samples/exp/eval.rb'
require 'core/semantics/code/interpreter'


class ExpTest < Test::Unit::TestCase

  def test_base
    interp = Interpreter(Eval)

    e = Loader.load("sample.exp")
    assert_equal(33, interp.eval(e))
    
    puts "EXP #{e}"
    puts "Children #{e.subexpressions}"
    a = e.subexpressions[0]
    puts "PARENT #{a.parent}"
  end

end

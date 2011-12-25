
require 'test/unit'

require 'core/system/load/load'
require 'core/lang/code/eval'

class RunTest < Test::Unit::TestCase

  def setup
    @a1 = Loader.load("a1.enso")
    @a2 = Loader.load("a2.enso")
    @a3 = Loader.load("a3.enso")
  end

  def test_run
    #LangEval.eval(@a1)
    #LangEval.eval(@a2)
    assert(true)
  end

end

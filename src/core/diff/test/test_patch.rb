
require 'test/unit'

require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/diff/code/delta'
require 'core/diff/code/diff'
require 'core/diff/code/patch'
require 'core/diff/code/equals'
require 'core/schema/code/factory'

class PatchTest < Test::Unit::TestCase

  # test setup
  def setup
    @point_schema = Load::load('diff-point.schema')
    @point_grammar = Load::load('diff-point.grammar')
    @p1 = Load::load('diff-test1.diff-point')
    @p2 = Load::load('diff-test2.diff-point')
  end

  # test reversible
  def test_reversible
    patch = Diff.diff(@p1, @p2)
    p3 = Patch.patch(@p1, patch)
    assert(Equals.equals(@p2, p3))
  end

end


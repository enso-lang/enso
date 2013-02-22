
require 'test/unit'

require 'core/system/load/load'
require 'core/schema/tools/diff'
require 'core/schema/tools/patch'
require 'core/schema/tools/equals'

class PatchTest < Test::Unit::TestCase

  # test setup
  def setup
    @point_schema = Load::load('point.schema')
    @point_grammar = Load::load('point.grammar')
    
    @p1 = Load::load('point1.point')
    @p2 = Load::load('point2.point')
  end

  # test reversible
  def test_reversible
    patch = Diff.diff(@p1, @p2)
    p3 = Patch.patch(@p1, patch)
    assert(Equals.equals(@p2, p3))
  end

end


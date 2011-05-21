
require 'test/unit'

require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/grammar/code/layout'
require 'core/diff/code/delta'
require 'core/diff/code/diff'
require 'core/diff/code/patch'
require 'core/diff/code/equals'
require 'core/schema/code/factory'

class PatchTest < Test::Unit::TestCase

  # test setup
  def setup
    @point_schema = Loader.load('diff-point.schema')
    @point_grammar = Loader.load('diff-point.grammar')
    @p1 = Loader.load('diff-test1.diff-point')
    @p2 = Loader.load('diff-test2.diff-point')
  end

  # test reversible
  def test_reversible
    patch = Diff.new.diff(@point_schema, @p1, @p2)
    p3 = Patch.patch!(@p1, patch)

    =begin
    puts "Result of p3 = patch!(p1, diff(p1, p2))"
    puts "p1="
    DisplayFormat.print(@point_grammar, @p1)
    puts "p2="
    DisplayFormat.print(@point_grammar, @p2)
    puts "p3="
    DisplayFormat.print(@point_grammar, p3)
    =end

    assert(Equals.equals(@p2, p3))
  end
  
end


require 'test/unit'

require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/diff/code/delta'
require 'core/diff/code/diff'
require 'core/schema/code/factory'

class DiffTest < Test::Unit::TestCase

  # test setup
  def setup
    @point_schema = Load::load('diff-point.schema')
    @point_grammar = Load::load('diff-point.grammar')
    
    @p1 = Load::load('diff-test1.diff-point')
    @p2 = Load::load('diff-test2.diff-point')
  end
  
  # test matching
  def test_match
    res = Match.new.match(@p1, @p2)
    assert_equal(10, res.size)
  end

  # test differencing
  def test_diff
    deltas = Diff.diff(@p1, @p2)
    assert_equal(11, deltas.size) #FIXME: this is a genuine bug to do with refs
  end  

  def test_diff2
=begin
    cons = Load::load('point.schema')
  
    ss = Load::load('schema.schema')
    gs = Load::load('grammar.schema')
    puts Diff.diff(ss, gs)

    #TODO: not sure how to check if this test is producing the right output
    #Print.print(delta)
=end
  end
end

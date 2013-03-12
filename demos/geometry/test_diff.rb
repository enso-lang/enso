
require 'test/unit'

require 'core/system/load/load'
require 'core/schema/tools/diff'

class DiffTest < Test::Unit::TestCase

  # test setup
  def setup
    @point_schema = Load::load('point.schema')
    @point_grammar = Load::load('point.grammar')
    
    @p1 = Load::load('point1.point')
    @p2 = Load::load('point2.point')
  end
  
  # test matching
  def test_match
    res = Diff::Match.new.match(@p1, @p2)
    assert_equal(10, res.size)
  end

  # test differencing
  def test_diff
    deltas = Diff.diff(@p1, @p2)
    puts deltas
    assert_equal(11, deltas.size) #FIXME: this is a genuine bug to do with refs
  end  

  def test_diff2
=begin
    cons = Load::load('point.schema')
  
    ss = Load::load('schema.schema')
    gs = Load::load('grammar.schema')
    puts Diff.diff(ss, gs)

    #TODO: not sure how to check if this test is producing the right output
    #Print::Print.print(delta)
=end
  end
end


require 'test/unit'

require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/grammar/render/layout'
require 'core/diff/code/delta'
require 'core/diff/code/diff'
require 'core/schema/code/factory'

class DiffTest < Test::Unit::TestCase

  # test setup
  def setup
    @point_schema = Loader.load('diff-point.schema')
    @point_grammar = Loader.load('diff-point.grammar')
    
    @p1 = Loader.load('diff-test1.diff-point')
    @p2 = Loader.load('diff-test2.diff-point')
  end
  
  # test matching
  def test_match
    res = Match.new.match(@p1, @p2)
    Print.print(@p1)
    Print.print(@p2)
    p res
    assert_equal(10, res.size)
  end

  # test differencing
  def test_diff
    deltas = Diff.diff(@p1, @p2)
    p deltas
    assert_equal(11, deltas.size)
  end  

  def test_diff2
=begin
    cons = Loader.load('point.schema')
  
    ss = Loader.load('schema.schema')
    gs = Loader.load('grammar.schema')
    puts Diff.diff(ss, gs)

    #TODO: not sure how to check if this test is producing the right output
    #Print.print(delta)
=end
  end
end

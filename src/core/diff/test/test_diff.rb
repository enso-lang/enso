
require 'test/unit'

require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/grammar/code/layout'
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
    assert_equal(res.size, 6)
  end

  # test differencing
  def test_diff
    res = Diff.new.diff(@point_schema, @p1, @p2)
    
    assert_equal(res.schema_class.name, DeltaTransform.modify+@p1.schema_class.name)
    
    assert_equal(res.lines[0].pts.length, 4)
  end  

  def test_diff2
    cons = Loader.load('point.schema')
  
    ss = Loader.load('schema.schema')
    gs = Loader.load('grammar.schema')
    delta = diff(ss, gs)

    #TODO: not sure how to check if this test is producing the right output
    #Print.print(delta)
  end
end

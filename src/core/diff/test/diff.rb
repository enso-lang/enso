
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
    point_schema = Loader.load('diff-point.schema')
    point_grammar = Loader.load('diff-point.grammar')
    
    p1 = Loader.load('diff-test1.diff-point')
    DisplayFormat.print(point_grammar, p1)
    
    p2 = Loader.load('diff-test2.diff-point')
    DisplayFormat.print(point_grammar, p2)
  end
  
  # test matching
  def match
    match = Match.new(Equals.new)
    puts match.match(p1, p2)
  end

  # test differencing
  def diff
    res = Diff.new.diff(point_schema, p1, p2)
    
    puts res.schema_class.name
    assert_equal(res.schema_class.name, DeltaTransform.modify+p1.schema_class.name)
    
    puts res.pts.length
    assert_equal(res.pts.length, 2)
  end  

end

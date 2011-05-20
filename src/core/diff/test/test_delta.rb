
require 'test/unit'

require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/grammar/code/layout'
require 'core/diff/code/delta'
require 'core/diff/code/diff'
require 'core/schema/code/factory'


class DeltaTest < Test::Unit::TestCase

  # test setup
  def setup
    point_schema = Loader.load('diff-point.schema')
    point_grammar = Loader.load('diff-point.grammar')
    
    p1 = Loader.load('diff-test1.diff-point')
    DisplayFormat.print(point_grammar, p1)
    
    p2 = Loader.load('diff-test2.diff-point')
    DisplayFormat.print(point_grammar, p2)
  end
  
  # test creation of delta schema
  def delta
    DisplayFormat.print(Loader.load('schema.grammar'), point_schema)
    deltaCons = DeltaTransform.new.Schema(point_schema)
    DisplayFormat.print(Loader.load('schema.grammar'), deltaCons)
  end
  
end

require 'test/unit'

require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/grammar/code/layout'
require 'core/diff/code/delta'
require 'core/diff/code/diff'
require 'core/schema/code/factory'


class DeltaTest < Test::Unit::TestCase
  
  # test creation of delta schema
  def test_delta_point
    puts "-"*50
    deltaCons = Delta(Loader.load('diff-point.schema'))
    DisplayFormat.print(Loader.load('schema.grammar'), deltaCons)
  end

  def test_delta_schema
    puts "-"*50
    deltaCons = Delta(Loader.load('schema.schema'))
    DisplayFormat.print(Loader.load('schema.grammar'), deltaCons)
  end

  def test_delta_grammar
    puts "-"*50
    deltaCons = Delta(Loader.load('grammar.schema'))
    DisplayFormat.print(Loader.load('schema.grammar'), deltaCons)
  end
  
end

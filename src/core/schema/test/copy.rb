
require 'test/unit'

require 'core/system/load/load'

require 'core/schema/code/factory'

require 'core/schema/tools/copy'
require 'core/schema/tools/print'
require 'core/diff/code/diff'

class CopyTest < Test::Unit::TestCase
  SS = Loader.load('schema.schema')
  GS = Loader.load('grammar.schema')
  GG = Loader.load('grammar.grammar')
  
  def test_SS
    s1 = SS
    s2 = Copy.new(Factory.new(SS)).copy(s1)
    assert_equal([], diff(s1, s2))
  end

  def test_parsetree_schema
    s1 = ParseTreeSchema.schema
    s2 = Copy.new(Factory.new(SS)).copy(s1)
    assert_equal([], diff(s1, s2))
  end

  def test_GS
    s1 = GS
    s2 = Copy.new(Factory.new(SS)).copy(s1)
    assert_equal([], diff(s1, s2))
  end

  def test_grammar_grammar
    s1 = GG
    s2 = Copy.new(Factory.new(GS)).copy(s1)
    assert_equal([], diff(s1, s2))
  end

end

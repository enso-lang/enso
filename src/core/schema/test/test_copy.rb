
require 'test/unit'

require 'core/system/load/load'

require 'core/schema/code/factory'

require 'core/schema/tools/copy'
require 'core/schema/tools/print'
require 'core/diff/code/equals'

class CopyTest < Test::Unit::TestCase
  SS = Loader.load('schema.schema')
  GS = Loader.load('grammar.schema')
  GG = Loader.load('grammar.grammar')
  
  def test_SS
    s1 = SS
    s2 = Copy.new(ManagedData::Factory.new(SS)).copy(s1)
    assert(Equals.equals(s1, s2))
  end

  def test_GS
    s1 = GS
    s2 = Copy.new(ManagedData::Factory.new(SS)).copy(s1)
    assert(Equals.equals(s1, s2))
  end

  def test_grammar_grammar
    s1 = GG
    s2 = Copy.new(ManagedData::Factory.new(GS)).copy(s1)
    assert(Equals.equals(s1, s2))
  end

end

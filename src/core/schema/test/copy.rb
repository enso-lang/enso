
require 'test/unit'

require 'core/system/boot/schema_schema'
require 'core/system/boot/grammar_schema'
require 'core/system/boot/grammar_grammar'
require 'core/system/boot/parsetree_schema'

require 'core/schema/code/factory'

require 'core/schema/tools/copy'
require 'core/schema/tools/print'
require 'core/diff/code/diff'

class CopyTest < Test::Unit::TestCase
  
  def test_schema_schema
    s1 = SchemaSchema.schema
    s2 = Copy.new(Factory.new(SchemaSchema.schema)).copy(s1)
    assert_equal([], diff(s1, s2))
  end

  def test_parsetree_schema
    s1 = ParseTreeSchema.schema
    s2 = Copy.new(Factory.new(SchemaSchema.schema)).copy(s1)
    assert_equal([], diff(s1, s2))
  end

  def test_grammar_schema
    s1 = GrammarSchema.schema
    s2 = Copy.new(Factory.new(SchemaSchema.schema)).copy(s1)
    assert_equal([], diff(s1, s2))
  end

  def test_grammar_grammar
    s1 = GrammarGrammar.grammar
    s2 = Copy.new(Factory.new(GrammarSchema.schema)).copy(s1)
    assert_equal([], diff(s1, s2))
  end

end

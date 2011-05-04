
require 'test/unit'

require 'schema/schemaschema'
require 'schema/factory'
require 'grammar/grammarschema'
require 'grammar/grammargrammar'
require 'grammar/parsetree'

require 'tools/copy'
require 'tools/diff'
require 'tools/print'

class CopyTest < Test::Unit::TestCase
  
  def test_schema_schema
    s1 = SchemaSchema.schema
    s2 = Copy.new(Factory.new(SchemaSchema.schema)).copy(s1)
    assert_equal([], Diff.diff(s1, s2))
  end

  def test_parsetree_schema
    s1 = ParseTreeSchema.schema
    s2 = Copy.new(Factory.new(SchemaSchema.schema)).copy(s1)
    assert_equal([], Diff.diff(s1, s2))
  end

  def test_grammar_schema
    s1 = GrammarSchema.schema
    s2 = Copy.new(Factory.new(SchemaSchema.schema)).copy(s1)
    assert_equal([], Diff.diff(s1, s2))
  end

  def test_grammar_grammar
    s1 = GrammarGrammar.grammar
    s2 = Copy.new(Factory.new(GrammarSchema.schema)).copy(s1)
    assert_equal([], Diff.diff(s1, s2))
  end

end

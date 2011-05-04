
require 'test/unit'

require 'schema/schemaschema'
require 'schema/factory'
require 'grammar/grammarschema'
require 'grammar/grammargrammar'
require 'grammar/parsetree'

require 'tools/copy'
require 'tools/equals'
require 'tools/print'

class EqualityTest < Test::Unit::TestCase
  
  def print_eq(s, x, y)
    s1 = ''
    s2 = ''
    Print.new(s1).recurse(x)
    Print.new(s2).recurse(y)
    if Equals.equals(s, x, y) then
      assert_equal(s1, s2, "objects are equal but print differently")
    else
      assert_not_equal(s1, s2, "objects are not equal, but print the same")
    end
  end
    


  def test_self_equals
    s1 = SchemaSchema.schema
    assert(Equals.equals(SchemaSchema.schema, s1, s1))
    s1 = ParseTreeSchema.schema
    assert(Equals.equals(SchemaSchema.schema, s1, s1))
    s1 = GrammarSchema.schema
    assert(Equals.equals(SchemaSchema.schema, s1, s1))
    s1 = GrammarGrammar.grammar
    assert(Equals.equals(GrammarSchema.schema, s1, s1))
  end

  def test_print_equals
    s1 = SchemaSchema.schema
    print_eq(s1, s1, s1)
    s1 = ParseTreeSchema.schema
    print_eq(s1, s1, s1)
    s1 = GrammarSchema.schema
    print_eq(s1, s1, s1)
    s2 = GrammarGrammar.grammar
    print_eq(s1, s2, s2)
  end


  def test_not_equals
    s1 = SchemaSchema.schema
    s2 = ParseTreeSchema.schema
    s3 = GrammarSchema.schema
    s4 = GrammarGrammar.grammar

    assert(!Equals.equals(SchemaSchema.schema, s1, s2))
    assert(!Equals.equals(SchemaSchema.schema, s2, s3))
    assert(!Equals.equals(SchemaSchema.schema, s3, s4))

    assert_raise(Exception, "cannot compare grammars using schemaschema") do
      Equals.equals(SchemaSchema.schema, s4, s4)
    end

    assert_raise(Exception, "should not compare grammars to schemas") do
      Equals.equals(SchemaSchema.schema, s4, s3)
    end

    assert_raise(Exception, "should not compare schemas to grammars") do
      Equals.equals(SchemaSchema.schema, s3, s4)
    end

    assert_raise(Exception, "should not compare schemas to grammars as if grammars") do
      Equals.equals(GrammarSchema.schema, s3, s4)
    end
  end



  def test_transitive
    s1 = SchemaSchema.schema
    s2 = Copy.new(Factory.new(SchemaSchema.schema)).copy(s1)
    s3 = Copy.new(Factory.new(SchemaSchema.schema)).copy(s2)
    assert(Equals.equals(SchemaSchema.schema, s1, s3))
  end

end

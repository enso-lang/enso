

require 'test/unit'

require 'core/grammar/code/parse'
require 'core/system/boot/parsetree_schema'
require 'core/system/boot/grammar_grammar'
require 'core/instance/code/instantiate'

require 'core/diff/code/equals'
require 'core/diff/code/diff'
require 'core/diff/code/merge'
require 'core/schema/tools/print'

class BootstrapTests < Test::Unit::TestCase

  GRAMMAR_GRAMMAR = 'core/grammar/models/grammar.grammar'
  GRAMMAR_SCHEMA = 'core/grammar/models/grammar.schema'
  PARSETREE_SCHEMA = 'core/grammar/models/parsetree.schema'

  CONSTRUCTOR_SCHEMA = 'core/instance/models/constructor.schema'

  SCHEMA_GRAMMAR = 'core/schema/models/schema.grammar'
  SCHEMA_SCHEMA = 'core/schema/models/schema.schema'

  def test_grammar_grammar
    grammar = GrammarGrammar.grammar

    assert(Equals.equals(GrammarSchema.schema, grammar, grammar))
    assert_equal([], Diff.diff(grammar, grammar))

    grammargrammar = GRAMMAR_GRAMMAR
    grammar2 = CPSParser.load(grammargrammar, grammar, GrammarSchema.schema)

    assert(Equals.equals(GrammarSchema.schema, grammar2, grammar2))
    assert(Equals.equals(GrammarSchema.schema, grammar, grammar2))
    assert(Equals.equals(GrammarSchema.schema, grammar2, grammar))

    assert_equal([], Diff.diff(grammar2, grammar2))
    assert_equal([], Diff.diff(grammar, grammar2))
    assert_equal([], Diff.diff(grammar2, grammar))
    
    grammar3 = CPSParser.load(grammargrammar, grammar2, GrammarSchema.schema)

    assert(Equals.equals(GrammarSchema.schema, grammar3, grammar3))
    assert(Equals.equals(GrammarSchema.schema, grammar2, grammar3))
    assert(Equals.equals(GrammarSchema.schema, grammar3, grammar2))
    assert(Equals.equals(GrammarSchema.schema, grammar3, grammar))
    assert(Equals.equals(GrammarSchema.schema, grammar, grammar3))

    assert_equal([], Diff.diff(grammar3, grammar3))
    assert_equal([], Diff.diff(grammar2, grammar3))
    assert_equal([], Diff.diff(grammar3, grammar2))
    assert_equal([], Diff.diff(grammar3, grammar))
    assert_equal([], Diff.diff(grammar, grammar3))

    grammar4 = CPSParser.load(grammargrammar, grammar3, GrammarSchema.schema)

    assert(Equals.equals(GrammarSchema.schema, grammar4, grammar4))
    assert(Equals.equals(GrammarSchema.schema, grammar4, grammar3))
    assert(Equals.equals(GrammarSchema.schema, grammar3, grammar4))
    assert(Equals.equals(GrammarSchema.schema, grammar4, grammar2))
    assert(Equals.equals(GrammarSchema.schema, grammar2, grammar4))
    assert(Equals.equals(GrammarSchema.schema, grammar4, grammar))
    assert(Equals.equals(GrammarSchema.schema, grammar, grammar4))

    assert_equal([], Diff.diff(grammar4, grammar4))
    assert_equal([], Diff.diff(grammar4, grammar3))
    assert_equal([], Diff.diff(grammar3, grammar4))
    assert_equal([], Diff.diff(grammar4, grammar2))
    assert_equal([], Diff.diff(grammar4, grammar))
    assert_equal([], Diff.diff(grammar, grammar4))
  end
  
  def test_schema_grammar
    grammar = GrammarGrammar.grammar
    grammar2 = CPSParser.load(SCHEMA_GRAMMAR, grammar, GrammarSchema.schema)
    schema_schema = CPSParser.load(SCHEMA_SCHEMA, grammar2, SchemaSchema.schema)

    assert_equal([], Diff.diff(SchemaSchema.schema, SchemaSchema.schema),
           "Boot SchemaSchema != Boot SchemaSchema")
  end

  def test_schema_schema_grammar
    equal([], Diff.diff(SchemaSchema.schema, SchemaSchema.schema),
      "Boot SchemaSchema != Boot SchemaSchema")

    grammar = GrammarGrammar.grammar
    grammar2 = CPSParser.load(SCHEMA_GRAMMAR, grammar, GrammarSchema.schema)
    schema_schema = CPSParser.load(SCHEMA_SCHEMA, grammar2, SchemaSchema.schema)

    assert_equal([], Diff.diff(schema_schema, SchemaSchema.schema),
           "SchemaSchema != Boot SchemaSchema")

    schema_schema2 = CPSParser.load(SCHEMA_SCHEMA, grammar2, schema_schema)
    assert_equal([], Diff.diff(schema_schema2, schema_schema2, schema_schema22),
           "Boot SchemaSchema !=  SchemaSchema")
  end

  def test_grammar_schema
    grammar = GrammarGrammar.grammar
    grammar2 = CPSParser.load(SCHEMA_GRAMMAR, grammar, GrammarSchema.schema)
    grammar_schema = CPSParser.parse(GRAMMAR_SCHEMA, grammar2)
    assert_not_nil(grammar_schema)
  end

  def test_parsetree_schema
    grammar = GrammarGrammar.grammar
    grammar2 = CPSParser.load(SCHEMA_GRAMMAR, grammar, GrammarSchema.schema)
    pt_schema = CPSParser.parse(PARSETREE_SCHEMA, grammar2)
    assert_not_nil(pt_schema)
  end

  def test_constructor_schema
    grammar = GrammarGrammar.grammar
    grammar2 = CPSParser.load(SCHEMA_GRAMMAR, grammar, GrammarSchema.schema)
    cons_schema = CPSParser.parse(CONSTRUCTOR_SCHEMA, grammar2)
    assert_not_nil(cons_schema)
  end

  def test_merged_parsetree_schema_equals_bootstrap_parsetree
    sg = CPSParser.load(SCHEMA_GRAMMAR, 
                        GrammarGrammar.grammar, 
                        GrammarSchema.schema)

    cons = CPSParser.load_raw(CONSTRUCTOR_SCHEMA, 
                              sg, SchemaSchema.schema)
    pt = CPSParser.load_raw(PARSETREE_SCHEMA, 
                            sg, SchemaSchema.schema)
    
    pt_plus_cons = Merge.new.merge(pt, cons, cons._graph_id, {
                                     "str" => "str", 
                                     "int" => "int", 
                                     "bool" => "bool",
                                     "Tree" => "Tree",
                                     "Value" => "Value",
                                     "Ref" => "Ref"
                                   })
    assert_equal([], Diff.diff(pt_plus_cons, ParseTreeSchema.schema))
  end


 def test_merged_grammar_schema_equals_bootstrap_grammar_schema
   sg = CPSParser.load(SCHEMA_GRAMMAR, 
                       GrammarGrammar.grammar, 
                       GrammarSchema.schema)
   
   cons = CPSParser.load_raw(CONSTRUCTOR_SCHEMA, 
                             sg, SchemaSchema.schema)
   gram = CPSParser.load_raw(GRAMMAR_SCHEMA, 
                             sg, SchemaSchema.schema)
   
   gram_plus_cons = Merge.new.merge(gram, cons, cons._graph_id,  {
                                      "str" => "str", 
                                      "int" => "int", 
                                      "bool" => "bool",
                                      "Expression" => "Tree"
                                    })
   assert_equal([], Diff.diff(gram_plus_cons, GrammarSchema.schema))
 end


end

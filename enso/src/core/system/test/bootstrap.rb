

require 'test/unit'

require 'grammar/cpsparser'
require 'grammar/parsetree'
require 'grammar/grammargrammar'
require 'grammar/instantiate'

require 'tools/equals'
require 'tools/diff'
require 'tools/print'
require 'tools/merge'

class BootstrapTests < Test::Unit::TestCase

  def test_grammar_grammar
    grammar = GrammarGrammar.grammar

    assert(Equals.equals(GrammarSchema.schema, grammar, grammar))
    assert_equal([], Diff.diff(grammar, grammar))

    grammargrammar = 'grammar/grammar.grammar'
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
    grammar2 = CPSParser.load('schema/schema.grammar', grammar, GrammarSchema.schema)
    schema_schema = CPSParser.load('schema/schema.schema', grammar2, SchemaSchema.schema)

    assert_equal([], Diff.diff(SchemaSchema.schema, SchemaSchema.schema),
           "Boot SchemaSchema != Boot SchemaSchema")
  end

  def test_grammar_schema
    grammar = GrammarGrammar.grammar
    grammar2 = CPSParser.load('schema/schema.grammar', grammar, GrammarSchema.schema)
    grammar_schema = CPSParser.parse('grammar/grammar.schema', grammar2)
    assert_not_nil(grammar_schema)
  end

  def test_parsetree_schema
    grammar = GrammarGrammar.grammar
    grammar2 = CPSParser.load('schema/schema.grammar', grammar, GrammarSchema.schema)
    pt_schema = CPSParser.parse('grammar/parsetree.schema', grammar2)
    assert_not_nil(pt_schema)
  end

  def test_constructor_schema
    grammar = GrammarGrammar.grammar
    grammar2 = CPSParser.load('schema/schema.grammar', grammar, GrammarSchema.schema)
    cons_schema = CPSParser.parse('grammar/constructor.schema', grammar2)
    assert_not_nil(cons_schema)
  end

  def test_merged_parsetree_schema_equals_bootstrap_parsetree
    sg = CPSParser.load('schema/schema.grammar', 
                        GrammarGrammar.grammar, 
                        GrammarSchema.schema)

    cons = CPSParser.load_raw('grammar/constructor.schema', 
                              sg, SchemaSchema.schema)
    pt = CPSParser.load_raw('grammar/parsetree.schema', 
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
   sg = CPSParser.load('schema/schema.grammar', 
                       GrammarGrammar.grammar, 
                       GrammarSchema.schema)
   
   cons = CPSParser.load_raw('grammar/constructor.schema', 
                             sg, SchemaSchema.schema)
   gram = CPSParser.load_raw('grammar/grammar.schema', 
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

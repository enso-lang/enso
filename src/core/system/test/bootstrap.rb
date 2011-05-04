

require 'test/unit'

require 'core/system/load/load'

require 'core/grammar/code/parse'
require 'core/system/boot/parsetree_schema'
require 'core/system/boot/grammar_grammar'
require 'core/instance/code/instantiate'

require 'core/diff/code/equals'
require 'core/diff/code/diff'
require 'core/diff/code/merge'
require 'core/schema/tools/print'

class BootstrapTests < Test::Unit::TestCase

  GRAMMAR_GRAMMAR = 'grammar.grammar'
  GRAMMAR_SCHEMA = 'grammar.schema'
  PARSETREE_SCHEMA = 'parsetree.schema'

  PROTO_SCHEMA = 'proto.schema'
  INSTANCE_SCHEMA = 'instance.schema'

  SCHEMA_GRAMMAR = 'schema.grammar'
  SCHEMA_SCHEMA = 'schema.schema'

  def test_grammar_grammar
    grammar = GrammarGrammar.grammar

    assert(Equals.equals(GrammarSchema.schema, grammar, grammar))
    assert_equal([], Diff.diff(grammar, grammar))

    grammargrammar = 'core/grammar/models/grammar.grammar'
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
    x = Loader.load(SCHEMA_SCHEMA)
    assert_equal([], Diff.diff(x, SchemaSchema.schema),
                 "Boot SchemaSchema != Boot SchemaSchema")
  end
  
  def test_parsetree_schema
    assert_not_nil(Loader.load(PARSETREE_SCHEMA))
  end

  def test_instance_schema
    assert_not_nil(Loader.load(INSTANCE_SCHEMA))
  end

  def test_merged_parsetree_schema_equals_bootstrap_parsetree
    pro = Loader.load(PROTO_SCHEMA)
    inst = Loader.load(INSTANCE_SCHEMA)
    pt = Loader.load(PARSETREE_SCHEMA)

    inst_plus_pro = Merge.new.merge(inst, pro, pro._graph_id, {
                                     "str" => "str",
                                      "Value" => "Value",
                                      "Tree" => "Tree"
                                   })

    pt_plus_inst_plus_pro = Merge.new.merge(pt, inst_plus_pro,
                                            inst_plus_pro._graph_id, {
                                              "str" => "str", 
                                              "int" => "int", 
                                              "bool" => "bool",
                                              "Tree" => "Tree",
                                              "Value" => "Value",
                                              "Ref" => "Ref"
                                            })
    assert_equal([], Diff.diff(pt_plus_inst_plus_pro, ParseTreeSchema.schema))
  end


 def test_merged_grammar_schema_equals_bootstrap_grammar_schema
   
   pro = Loader.load(PROTO_SCHEMA)
   gram = Loader.load(GRAMMAR_SCHEMA)

   gram_plus_pro = Merge.new.merge(gram, pro, pro._graph_id,  {
                                     "str" => "str", 
                                     "int" => "int", 
                                     "bool" => "bool",
                                     "Expression" => "Tree",
                                     "Value" => "Value"
                                   })
   assert_equal([], Diff.diff(gram_plus_pro, GrammarSchema.schema))
 end


end

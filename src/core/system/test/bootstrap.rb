

require 'test/unit'

require 'core/system/load/load'

require 'core/grammar/parse/parse'
require 'core/system/boot/grammar_grammar'
require 'core/instance/code/instantiate'

require 'core/diff/code/equals'
require 'core/diff/code/diff'
require 'core/schema/tools/print'

class BootstrapTests < Test::Unit::TestCase

  GRAMMAR_GRAMMAR = 'grammar.grammar'
  GRAMMAR_SCHEMA = 'grammar.schema'

  PROTO_SCHEMA = 'proto.schema'
  INSTANCE_SCHEMA = 'instance.schema'

  SCHEMA_GRAMMAR = 'schema.grammar'
  SCHEMA_SCHEMA = 'schema.schema'

  def test_boot_SchemaSchema
    assert(Equals.equals(Loader.load(SCHEMA_SCHEMA), SchemaSchema.schema))
  end
  def test_boot_GrammarSchema
    assert(Equals.equals(Loader.load(GRAMMAR_SCHEMA), GrammarSchema.schema))
  end
  def test_boot_GrammarGrammar
    assert(Equals.equals(Loader.load(GRAMMAR_GRAMMAR), GrammarGrammar.grammar))
  end
  def test_diff_boot_GrammarGrammar
    assert_equal(nil, Diff.new.diff(Loader.load(GRAMMAR_SCHEMA), Loader.load(GRAMMAR_GRAMMAR), GrammarGrammar.grammar))    
  end  

  def test_grammar_grammar
    grammar = GrammarGrammar.grammar

    assert(Equals.equals(grammar, grammar))
    assert(!Equals.equals(grammar, Loader.load(SCHEMA_GRAMMAR)))
   
    grammargrammar = 'core/grammar/models/grammar.grammar'
    grammar2 = Parse.load_file(grammargrammar, grammar, GrammarSchema.schema)

    assert(Equals.equals(grammar2, grammar2))
    assert(Equals.equals(grammar, grammar2))
    assert(Equals.equals(grammar2, grammar))

    grammar3 = Parse.load_file(grammargrammar, grammar2, GrammarSchema.schema)

    assert(Equals.equals(grammar3, grammar3))
    assert(Equals.equals(grammar2, grammar3))
    assert(Equals.equals(grammar3, grammar2))
    assert(Equals.equals(grammar3, grammar))
    assert(Equals.equals(grammar, grammar3))

    grammar4 = Parse.load_file(grammargrammar, grammar3, GrammarSchema.schema)

    assert(Equals.equals(grammar4, grammar4))
    assert(Equals.equals(grammar4, grammar3))
    assert(Equals.equals(grammar3, grammar4))
    assert(Equals.equals(grammar4, grammar2))
    assert(Equals.equals(grammar2, grammar4))
    assert(Equals.equals(grammar4, grammar))
    assert(Equals.equals(grammar, grammar4))
  end
  
  def test_schema_grammar
    x = Loader.load(SCHEMA_SCHEMA)
    assert(Equals.equals(x, SchemaSchema.schema),
                 "Loaded SchemaSchema != Boot SchemaSchema")
  end
  
  def test_instance_schema
    assert_not_nil(Loader.load(INSTANCE_SCHEMA))
  end
end

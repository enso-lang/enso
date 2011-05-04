

require 'test/unit'

require 'core/grammar/code/parse'
require 'core/grammar/code/unparse'
require 'core/grammar/code/layout'

require 'core/system/boot/parsetree_schema'
require 'core/system/boot/grammar_grammar'
require 'core/instance/code/instantiate'
require 'core/diff/code/diff'
require 'core/schema/code/factory'

class ParseTest < Test::Unit::TestCase

  GRAMMAR_GRAMMAR = 'core/grammar/models/grammar.grammar'
  SCHEMA_GRAMMAR = 'core/schema/models/schema.grammar'
  SCHEMA_SCHEMA = 'core/schema/models/schema.schema'

  def test_parse_unparse
    grammar = GrammarGrammar.grammar
    grammargrammar = GRAMMAR_GRAMMAR
    src = File.read(grammargrammar)
    tree = CPSParser.parse(grammargrammar, grammar)
    s = Unparse.unparse(grammar, tree)
    assert_equal(src, s, "unparse not the same as input source")
  end
 
  def test_parse_render
    boot = GrammarGrammar.grammar
    grammar1 = CPSParser.load(GRAMMAR_GRAMMAR, boot, GrammarSchema.schema)
    s = ''
    DisplayFormat.print(GrammarGrammar.grammar, grammar1, 80, s)
    parse = CPSParser.new(s, Factory.new(ParseTreeSchema.schema))
    pt = parse.run(grammar1)
    grammar2 = Instantiate.new(Factory.new(GrammarSchema.schema)).run(pt)
    assert_equal([], Diff.diff(grammar1, grammar2))
  end


end

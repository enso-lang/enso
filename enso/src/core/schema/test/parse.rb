


require 'test/unit'

require 'grammar/cpsparser'
require 'grammar/parsetree'
require 'grammar/grammargrammar'
require 'grammar/unparse'
require 'grammar/instantiate'
require 'tools/diff'
require 'grammar/layout'
require 'schema/factory'

class ParseTest < Test::Unit::TestCase

  def test_parse_unparse
    grammar = GrammarGrammar.grammar
    grammargrammar = 'grammar/grammar.grammar'
    src = File.read(grammargrammar)
    tree = CPSParser.parse(grammargrammar, grammar)
    s = Unparse.unparse(grammar, tree)
    assert_equal(src, s, "unparse not the same as input source")
  end
 
  def test_parse_render
    boot = GrammarGrammar.grammar
    grammar1 = CPSParser.load('grammar/grammar.grammar', boot, GrammarSchema.schema)
    s = ''
    DisplayFormat.print(GrammarGrammar.grammar, grammar1, 80, s)
    parse = CPSParser.new(s, Factory.new(ParseTreeSchema.schema))
    pt = parse.run(grammar1)
    grammar2 = Instantiate.new(Factory.new(GrammarSchema.schema)).run(pt)
    assert_equal([], Diff.diff(grammar1, grammar2))
  end

end

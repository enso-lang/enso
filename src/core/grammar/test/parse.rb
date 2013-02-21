

require 'test/unit'

require 'core/grammar/parse/parse'
require 'core/grammar/render/layout'

require 'core/diff/code/diff'
require 'core/schema/code/factory'

class ParseTest < Test::Unit::TestCase

  GRAMMAR_GRAMMAR = 'core/grammar/models/grammar.grammar'
  
  def test_parse_render
    gg = Load('grammar.grammar')
    gs = Load('grammar.schema')
    grammar1 = Parse.load_file(GRAMMAR_GRAMMAR, gg, gs)
    s = ''
    Layout::DisplayFormat.print(gg, grammar1, s)
    grammar2 = Parse.load(s, gg, gs)
    assert_equal(nil, diff(grammar1, grammar2))
  end


end

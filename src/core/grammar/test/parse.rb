

require 'test/unit'

require 'core/system/load/load'
require 'core/grammar/parse/parse'
require 'core/grammar/render/layout'

require 'core/schema/tools/diff'
require 'core/schema/code/factory'

class ParseTest < Test::Unit::TestCase

  GRAMMAR_GRAMMAR = 'core/grammar/models/grammar.grammar'
  
  def test_parse_render
    gg = Load::load('grammar.grammar')
    gs = Load::load('grammar.schema')
    s = File.new("JUNK", "w")
    Layout::DisplayFormat.print(gg, gg, s)
    grammar2 = Parse.load(s, gg, gs)
    assert_equal([], Diff::diff(gg, grammar2))
  end

end

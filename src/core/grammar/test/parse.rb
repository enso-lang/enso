

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
#    s = File.new("JUNK", "w")
#    Layout::DisplayFormat.print(gg, gg, s)
    
    #s = File.new("JUNK", "r")
    grammar1 = Parse.load_file("core/schema/models/schema.grammar", gg, gs)
    grammar2 = Parse.load_file("core/schema/models/schema.grammar", gg, gs)
    assert_equal([], Diff::diff(grammar1, grammar2))
  end

end

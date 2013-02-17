require 'test/unit'

require 'core/system/load/load'
require 'core/semantics/code/interpreter'
require 'core/feature/code/load'

class LoadTest < Test::Unit::TestCase

  def test_web
    #load manually created
    ws1 = union(Load::load('web-base.schema'), rename(Load::load('element.schema'), {'Value' => 'Exp', 'Content' => 'Stat'}))
    wg1 = union(Load::load('web-base.grammar'), rename(Load::load('element.grammar'), {'Value' => 'Exp', 'Content' => 'Stat'}))
    wg1.start = wg1.rules[Load::load('web-base.grammar').start.name]

    #load feature
    webfeat = Load::load('testfeat-web.feature')
    Interpreter(BuildFeature).build(webfeat)
    ws = Load::load('web.schema')
    wg = Load::load('web.grammar')

    assert(Equals.equals(ws1, ws))
    assert(Equals.equals(wg1, wg))
  end

end

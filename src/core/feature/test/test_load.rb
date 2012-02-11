require 'test/unit'

require 'core/system/load/load'
require 'core/semantics/code/interpreter'
require 'core/feature/code/load'

class LoadTest < Test::Unit::TestCase

  def test_web
    #load manually created
    ws1 = union(Loader.load('web-base.schema'), rename(Loader.load('element.schema'), {'Value' => 'Exp', 'Content' => 'Stat'}))
    wg1 = union(Loader.load('web-base.grammar'), rename(Loader.load('element.grammar'), {'Value' => 'Exp', 'Content' => 'Stat'}))
    wg1.start = wg1.rules[Loader.load('web-base.grammar').start.name]

    #load feature
    webfeat = Loader.load('testfeat-web.feature')
    Interpreter(BuildFeature).build(webfeat)
    ws = Loader.load('web.schema')
    wg = Loader.load('web.grammar')

    assert(Equals.equals(ws1, ws))
    assert(Equals.equals(wg1, wg))
  end

end

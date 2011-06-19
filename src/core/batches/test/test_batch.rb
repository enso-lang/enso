
require 'test/unit'

require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/grammar/code/layout'
require 'core/schema/code/factory'
require 'core/batches/code/batchtransform'

class BatchTest < Test::Unit::TestCase

  # test setup
  def setup
  end

  # test reversible
  def test_reversible
    todo = Loader.load('todo2.web')
    schema = Loader.load('todo.schema')
    Print.print(todo)
    res = BatchTransform.batch_web(todo, schema.classes['Todos'])
    Print.print(res['index'])
  end
  
end

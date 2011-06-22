
require 'test/unit'

require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/grammar/code/layout'
require 'core/schema/code/factory'
require 'core/batches/code/batchtransform'
require 'core/batches/code/securebatch'

class BatchTest < Test::Unit::TestCase

  # test setup
  def setup
  end

  def test_securebatch
    todo = Loader.load('todo2.web')
    schema = Loader.load('todo.schema')
    Print.print(todo)
    query = BatchTransform.batch_web(todo, schema.classes['Todos'])
    Print.print(query['index'])

    rules = Security.new('todo.auth')
    rules.user = "Emily"
    query.values.each do |q|
      q2 = SecureBatch.secure_transform!(q, rules)
    end

    Print.print(query['index'])
  end

  def test_inlinecalls
    todo = Loader.load('todo3.web')
    schema = Loader.load('todo.schema')
    Print.print(todo)
    res = BatchTransform.batch_web(todo, schema.classes['Todos'])
    Print.print(res['index'])
  end

end


require 'test/unit'

require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/grammar/render/layout'
require 'core/schema/code/factory'
require 'core/schema/tools/equals'
require 'apps/batches/code/batcheval'
require 'apps/batches/code/securebatch'

class BatchTest < Test::Unit::TestCase

  # test setup
  def setup
    @factory = Factory::SchemaFactory.new(Load::load('batch.schema'))

    #oracle for todo2
    @expected_todo2 = @factory.Query("Todos")
    @expected_todo2.filter = @factory.EBoolConst(true)
    f = @factory.Field("todos")
    @expected_todo2.fields << f
    q = @factory.Query("Todo")
    q.filter = @factory.EBinOp("or", @factory.EField(@factory.EVar("@self"), "done"), @factory.EField(@factory.EVar("@self"), "done"))
    f.query = q
    f = @factory.Field("todo")
    q.fields << f
    f = @factory.Field("done")
    q.fields << f
    f = @factory.Field("related")
    q.fields << f
    q = @factory.Query("Todo")
    q.filter = @factory.EField(@factory.EVar("@self"), "done")
    f.query = q
    f = @factory.Field("todo")
    q.fields << f

    @expected_todo3 = @expected_todo2

    @expected_todo4 = @factory.Query("Todos")
    @expected_todo4.filter = @factory.EBoolConst(true)
    f = @factory.Field("todos")
    @expected_todo4.fields << f
    q = @factory.Query("Todo")
    q.filter = @factory.EBoolConst(true)
    f.query = q
    f = @factory.Field("todo")
    q.fields << f
    f = @factory.Field("done")
    q.fields << f
  end

  def test_securebatch
    todo = Load::load('todo2.web')
    schema = Load::load('todo.schema')
    Print::Print.print(todo)
    query = BatchEval.batch(todo, schema.types['Todos'])
    Print::Print.print(query['index'])

    # Emily can only read todos that are not done
    rules = Security.new('todo.auth')
    rules.user = "Emily"
    query.values.each do |q|
      q2 = SecureBatch.secure_transform!(q, rules)
    end

    Print::Print.print(query['index'])
  end

  def test_batch_todo2
    todo = Load::load('todo2.web')
    schema = Load::load('todo.schema')
    res = BatchEval.batch(todo, schema.types['Todos'])
    assert(Equals.equals(res["index"], @expected_todo2))
  end

  def test_inlinecalls
    todo = Load::load('todo3.web')
    schema = Load::load('todo.schema')
    res = BatchEval.batch(todo, schema.types['Todos'])
    assert(Equals.equals(res["index"], @expected_todo3))
  end

  def test_tailcalls
    todo = Load::load('todo4.web')
    schema = Load::load('todo.schema')
    res = BatchEval.batch(todo, schema.types['Todos'])
    assert(Equals.equals(res["index"], @expected_todo4))
  end
end

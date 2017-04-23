require 'test/unit'

require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/schema/tools/union'
require 'core/schema/tools/equals'
require 'core/security/code/securefactory'
require 'core/semantics/code/interpreter'


class SecurityTest < Test::Unit::TestCase

  def setup
    # interp = SecureFactory.new
    sfactory = Interpreter(FactorySchema, SecureFactory.SecureFactoryMixin).Make(schema, rules: rules, :fail_silent=>true)
    factory = Factory::new(schema)

    schema = Load::load('todo.schema')
    sfact = interp.Make(schema, rules: Load::load('todo.auth'), fail_silent: false)
    @todo = sfact.make_secure(Load::load('test.todo'))
  end

  def test_read
    @todo.factory.user = 'Alice'
    assert(@todo.todos.size == 2)

    @todo.factory.user = 'Bob'
    assert(@todo.todos.size == 1)
  end

  def test_write
    @todo.factory.user = 'Alice'
    @todo.todos[0].todo = "Test Message"
    assert(@todo.todos[0].todo == "Test Message")

    @todo.factory.user = 'Bob'
    @todo.todos[0].todo = "Test Message"
    assert(@todo.todos[0].todo == "Test Message")
    @todo.factory.user = 'Alice'
    assert(@todo.todos.all?{|t| t.todo == "Test Message" })
  end

  def test_create
    @todo.factory.user = 'Alice'
    newtodo = @todo.factory["Todo"]
    @todo.todos << newtodo
    assert(@todo.todos.size == 3)

    assert_raise(SecurityError) {
      @todo.factory.user = 'Cathy'
      newtodo = @todo.factory["Todo"]
      @todo.todos << newtodo
    }
  end

  def test_delete
    @todo.factory.user = 'Alice'
    newtodo = @todo.factory["Todo"]
    @todo.todos.delete(@todo.todos[0])
    assert(@todo.todos.size == 1)

    @todo.factory.user = 'Dave'
    assert_raise(SecurityError) {
      @todo.todos.delete(@todo.todos[0])
    }
    assert(@todo.todos.size == 1)
  end

#  TODO: Interpreter model does not support constraints
#
#  def test_constraints
#    fact = Factory::new(Load::load("auth.schema"))
#
#    alice_const = fact.EBoolConst(true)
#   @todo.factory.user = 'Alice'
#    assert(Equals.equals(@todo.factory.get_allow_constraints("OpRead", "Todo"), alice_const))
#
#   bob_const = fact.EField(fact.EVar("@self"), "done")
#    @todo.factory.user = 'Bob'
#    assert(Equals.equals(@todo.factory.get_allow_constraints("OpRead", "Todo"), bob_const))
#
#    emily_const = fact.EUnOp("not", fact.EField(fact.EVar("@self"), "done"))
#    @todo.factory.user = 'Emily'
#    assert(Equals.equals(@todo.factory.get_allow_constraints("OpRead", "Todo"), emily_const))
#  end
end

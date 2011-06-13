
require 'test/unit'

require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/grammar/code/layout'
require 'core/schema/tools/union'
require 'core/security/code/securefactory'

class SecurityTest < Test::Unit::TestCase

  def setup
    @todo = SecureFactory.make_secure(Loader.load('test.todo'), 'todo.auth')
  end

  def test_read
    @todo.factory.set_user('Alice')
    assert(@todo.todos.length == 2)

    @todo.factory.set_user('Bob')
    assert(@todo.todos.length == 1)
  end

  def test_write
    @todo.factory.set_user('Alice')
    @todo.todos[0].todo = "Test Message"
    assert(@todo.todos[0].todo == "Test Message")

    @todo.factory.set_user('Bob')
    @todo.todos[0].todo = "Test Message"
    assert(@todo.todos[0].todo == "Test Message")
    @todo.factory.set_user('Alice')
    assert(@todo.todos.all?{|t| t.todo == "Test Message" })
  end

  def test_create
    @todo.factory.set_user('Alice')
    newtodo = @todo.factory["Todo"]
    @todo.todos << newtodo
    assert(@todo.todos.length == 3)

    assert_raise(SecurityError) {
      @todo.factory.set_user('Cathy')
      newtodo = @todo.factory["Todo"]
      @todo.todos << newtodo
    }
  end

  def test_delete
    @todo.factory.set_user('Alice')
    newtodo = @todo.factory["Todo"]
    @todo.todos.delete(@todo.todos[0])
    assert(@todo.todos.length == 1)

    @todo.factory.set_user('Dave')
    assert_raise(SecurityError) {
      @todo.todos.delete(@todo.todos[0])
    }
    assert(@todo.todos.length == 1)
  end

end

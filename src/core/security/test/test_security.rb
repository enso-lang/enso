
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
    assert_nothing_raised() {
      @todo.factory.set_user('Alice')
      Print.print(@todo)         # no errors
    }
    assert_raise(SecurityError) {
      @todo.factory.set_user('Bob')
      Print.print(@todo)         # security error
    }
  end

  def test_write
    assert_nothing_raised() {
      @todo.factory.set_user('Alice')
      @todo.todos[0].done = true
    }
    assert_raise(SecurityError) {
      @todo.factory.set_user('Bob')
      @todo.todos[0].done = true
    }
  end

  def test_create
    assert_nothing_raised() {
      @todo.factory.set_user('Alice')
      newtodo = @todo.factory["Todo"]
      @todo.todos << newtodo
    }
    assert_raise(SecurityError) {
      @todo.factory.set_user('Cathy')
      newtodo = @todo.factory["Todo"]
      @todo.todos << newtodo
    }
  end

  def test_delete
    assert_nothing_raised() {
      @todo.factory.set_user('Alice')
      newtodo = @todo.factory["Todo"]
      @todo.todos.delete(@todo.todos[0])
    }
    assert_raise(SecurityError) {
      @todo.factory.set_user('Dave')
      newtodo = @todo.factory["Todo"]
      @todo.todos.delete(@todo.todos[0])
    }
  end

end

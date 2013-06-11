require 'test/unit'

require 'core/system/load/load'

# Tests for schema models. Mainly computed fields
class ModelTest < Test::Unit::TestCase
  def test_key
    ss = Load::load('schema.schema')
    class_class = ss.types['Class']
    assert_equal("name", class_class.key.name)
    int_class = ss.types['int']
    assert_equal(nil, int_class.key)
    schema_class = ss.schema_class
    assert_equal(nil, schema_class.key)
  end
end

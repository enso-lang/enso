require 'core/system/boot/meta_schema'
require 'core/system/load/load'
require 'core/schema/tools/dumpjson'
require 'core/schema/tools/equals'
require 'test/unit'

class BootstrapTests < Test::Unit::TestCase

  def test_load
    ss = Load::load("schema.schema")
    assert(ss)
  end
  
  def test_1
    ss = Load::load("schema.schema")
    assert("Type" == ss.types['Field'].defined_fields['type'].type.name)
  end
  
  def test_2
    ss = Load::load("schema.schema")
    assert("Class" == ss.types['Field'].schema_class.name)
  end
  
  def test_3
    ss = Load::load("schema.schema")
    assert("Primitive" == ss.types['int'].schema_class.name)
  end
  
  def test_4
    ss = Load::load("schema.schema")
    assert(6 == ss.types['Class'].defined_fields.size)
  end
  
  def test_5
    ss = Load::load("schema.schema")
    assert(ss.types['Field'] == ss.types['Class'].defined_fields['defined_fields'].type)
  end
 end

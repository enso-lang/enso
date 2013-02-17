require 'core/system/boot/meta_schema'
require 'core/system/load/load'
require 'core/schema/tools/dumpjson'
require 'core/diff/code/equals'
require 'test/unit'

class BootstrapTests < Test::Unit::TestCase

  def test_load
    ss = Boot.load_path("core/system/boot/schema_schema.json")
    assert(ss)
  end
  
  def test_1
    ss = Boot.load_path("core/system/boot/schema_schema.json")
    assert("Type" == ss.types['Field'].defined_fields['type'].type.name)
  end
  
  def test_2
    ss = Boot.load_path("core/system/boot/schema_schema.json")
    assert("Class" == ss.types['Field'].schema_class.name)
  end
  
  def test_3
    ss = Boot.load_path("core/system/boot/schema_schema.json")
    assert("Primitive" == ss.types['int'].schema_class.name)
  end
  
  def test_4
    ss = Boot.load_path("core/system/boot/schema_schema.json")
    assert(5 == ss.types['Class'].defined_fields.length)
  end
  
  def test_5
    ss = Boot.load_path("core/system/boot/schema_schema.json")
    assert(ss.types['Field'] == ss.types['Class'].defined_fields['defined_fields'].type)
  end
  
  def test_6
    ss = Boot.load_path("core/system/boot/schema_schema.json")
    realss = Load::load('schema.schema')
    
    puts "Writing new metaschema"  
    ss_path = 'schema_schema2.json'
    File.open(ss_path, 'w+') do |f| 
      f.write(JSON.pretty_generate(ToJSON.to_json(realss, true)))
    end
    assert( Equals.equals(realss, ss) )
  end
end

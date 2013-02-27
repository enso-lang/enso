require 'core/system/boot/meta_schema'
require 'core/system/load/load'
require 'core/schema/tools/dumpjson'
require 'core/schema/tools/equals'

puts "Loading..."  
ss = MetaSchema::load_path("core/system/boot/schema_schema.json")

puts "Testing"
puts "Test1: Type=#{ss.types['Field'].defined_fields['type'].type.name}"
puts "Test2: Class=#{ss.types['Field'].schema_class.name}"
puts "Test2: Primitive=#{ss.types['int'].schema_class.name}"
puts "Test3: 5=#{ss.types['Class'].defined_fields.length}"
puts "Test4: " + (ss.types['Class'].defined_fields['defined_fields'].type==ss.types['Field'] ? "OK" : "Fail!")

puts "Done loading new metaschema"

realss = Load::load('schema.schema')

puts "Writing new metaschema"  
ss_path = 'schema_schema2.json'
File.open(ss_path, 'w+') do |f| 
  f.write(JSON.pretty_generate(Dumpjson::to_json(realss, true)))
end
print "Equality test: "
raise "Wrong result!" unless Equals.equals(realss, ss)

puts "All OK!"

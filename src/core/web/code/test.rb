

require 'core/system/load/load'
require 'core/schema/tools/print'

#wg = Loader.load('web.grammar')
w = Loader.load('web.schema')
e = Loader.load('example.web')


puts e.to_s
x = w.schema_class.schema.classes["Klass"]

w.classes.each do |y|
  if y.schema_class == x then
    puts y.to_s
  end
end

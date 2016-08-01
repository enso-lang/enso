require 'core/system/load/load'
require 'core/schema/code/factory'


f = Factory::new(Load::load("grades.schema"))

s1 = f["Student"]
s1.id = "#1"
s1.name = "William Cook"

g = f["Grading"]

g.students << s1

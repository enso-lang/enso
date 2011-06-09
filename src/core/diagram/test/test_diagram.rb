

require 'core/diagram/code/diagram'
require 'core/system/load/load'
require 'core/schema/tools/print'


diagram_schema = Loader.load('diagram.schema')

f = Factory.new(diagram_schema)

red = f.Color(255, 0, 0)
blue = f.Color(0, 0, 255)
black = f.Color(0, 0, 0)
white = f.Color(255, 255, 255)
font = f.Font("Helvetica", 18, true, true, red)
redpen = f.Pen(5, "", red)
brwhite = f.Brush(white)
bluepen = f.Pen(10, "", blue)
max = f.Constraint(100, false)
t1 = f.Text(nil, nil, nil, 99, 99, "Hello World")
t2 = f.Text(nil, nil, nil, 99, 99, "Enso!")
s1 = f.Shape(f.Point(10, 10), nil, nil, [redpen], nil, nil, t2)
s2 = f.Shape(f.Point(20, 20), nil, nil, [bluepen], nil, nil, t1)
content = f.Container(nil, max, max, [font, brwhite], nil, nil, 1, [s1, s2])

Print.print(content)

ViewDiagram(content, f)

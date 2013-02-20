

require 'core/diagram/code/diagram'
require 'core/system/load/load'
require 'core/schema/tools/print'


diagram_schema = Loader.load('diagram.schema')

f = ManagedData::Factory.new(diagram_schema)

red = f.Color(255, 0, 0)
blue = f.Color(0, 0, 255)
black = f.Color(0, 0, 0)
green = f.Color(0, 255, 0)
white = f.Color(255, 255, 255)
font = f.Font("Helvetica", 18, "swiss", 400, red)
redpen = f.Pen(5, "", red)
brwhite = f.Brush(white)
bluepen = f.Pen(10, "", blue)
greenpen = f.Pen(1, "", green)
max = f.Constraint(100, false)
t1 = f.Text(nil, nil, "Hello World")
t2 = f.Text(nil, nil, "Enso! Enso! Enso! Enso! Enso!")
s1 = f.Shape( nil, [bluepen], t1)
s2 = f.Shape( nil, [redpen], t2)
c1 = f.Container(nil, [font, brwhite], 1, [t2, t1])
content = f.Shape(nil, [greenpen], c1)
Print.print(content)

RunDiagramApp(content)

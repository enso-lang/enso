

require 'core/diagram/code/diagram'
require 'core/system/load/load'
require 'core/schema/tools/print'


diagram_schema = Loader.load('diagram.schema')

f = ManagedData::Factory.new(diagram_schema)

max = f.Constraint(100, "foo")
t1 = f.Text(nil, nil, "Hello World")
t2 = f.Text(nil, nil, "Enso! Enso! Enso! Enso! Enso!")
s1 = f.Shape( nil, nil, "box", t1)
s2 = f.Shape( nil, nil, "box", t2)
c1 = f.Container(nil, nil, 1, [t2, t1])
content = f.Shape(nil, nil, "box", c1)
content.finalize
Print.print(content)

RunDiagramApp(content)

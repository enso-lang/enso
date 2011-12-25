require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/grammar/code/layout'
require 'core/interp-dsl/code/interp-eval.rb'
require 'core/interp-dsl/code/interp-type.rb'

myschool = Loader.load('test.school')
sch_interp = Loader.load('school.interp')

typ = InterpType.type(sch_interp)
puts "Type is #{InterpType.subtype(typ, myschool.schema_class.schema) ? "OK!" : "no good!"}"

interp = Interpreter.new(sch_interp)
interp.interpret(myschool)


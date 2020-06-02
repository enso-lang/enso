
require 'core/system/load/load'
require 'core/schema/tools/print'

require 'demo/StateMachine/code/state_machine'

sm_schema = Load::load("state_machine.schema")
factory = Factory::SchemaFactory.new(sm_schema)
sm = factory.Machine
open = factory.State(sm, "Open")
closed = factory.State(sm, "Closed")
factory.Transition("close", open, closed)
factory.Transition("open", closed, open)
sm.start = open
sm.finalize

Print::Print.print(sm)

run_state_machine(sm)

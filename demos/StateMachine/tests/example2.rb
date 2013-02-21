require 'core/system/load/load'
require 'applications/StateMachine/code/state_machine'

sm = Load::load("door.state_machine")

run_state_machine(sm)


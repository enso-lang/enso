require 'core/system/load/load'
require 'applications/StateMachine/code/state_machine'

sm = Loader.load("door.state_machine")

run_state_machine(sm)


require 'core/system/load/load'
require 'core/semantics/interpreters/debug'
require 'demo/StateMachine/code/state_machine_basic'

Cache.clean('door.state_machine') #need to clean cache to get origin tracking
sm = Load::load('door.state_machine')

class Run::RunStateMachineC
  include Debug::Debug
  def run(obj)
    wrap(:run, :debug, obj)
  end
end

interp = Run::RunStateMachineC.new

#run it!
interp.run(sm)


require 'core/system/load/load'
require 'core/semantics/interpreters/debug'
require '../demos/StateMachine/code/state_machine_basic'

#Fibo is the fibonacci function. Source found in core/expr/test/fibo.impl
# Note that the whole program is surrounded by an implicit block (EBlock)
# with two statements: the fun def and the fun call

Cache.clean('door.state_machine') #need to clean cache to get origin tracking
sm = Load::load('door.state_machine')
FindModel::FindModel.find_model('door.state_machine') {|path| $file = IO.readlines(path)}

#EvalCommandC.new is the non-debug version
# DebugMod is parameterized by the interpreter (ie EvalCommand),

  class DebugRunSMC
    include Run::RunStateMachine
    include Debug::Debug
    def run(obj)
      wrap(:run, :debug, obj)
    end
  end

interp = DebugRunSMC.new

#run it!
interp.dynamic_bind stack: [], this: sm do
  interp.run(sm)
end


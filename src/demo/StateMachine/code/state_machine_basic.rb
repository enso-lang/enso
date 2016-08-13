
require 'core/system/load/load'
require 'core/schema/tools/print'

module Run

  module RunStateMachine
    include Interpreter::Dispatcher

    def run(obj)
      dispatch_obj(:run, obj)
    end

    def run_Machine(obj)
      current = obj.start
      while true
        current = run(current)
      end
    end
   
    def run_State(obj)
      # ask user for transition
      puts "\n>> current state: "+obj.name.to_s
      #@D._bind(:event, $stdin.gets)
      @event = $stdin.gets
      if @event.nil?
      	exit
      end
      @event = @event.strip
      # fire applicable transition
      new = obj.out.detect do |trans|
        run(trans)
      end
      new = new || obj
      new
    end

    def run_Trans(obj)
      # if event matches, fire transition
      if @event == obj.event.to_s
        obj.to
      end
    end
  end

  class RunStateMachineC
    include RunStateMachine
  end
end

def run_state_machine(sm)
  interp = Run::RunStateMachineC.new
  interp.dynamic_bind do
    interp.run(sm)
  end
end

sm = Load::load(ARGV[0])
run_state_machine(sm)


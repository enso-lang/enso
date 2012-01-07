require 'core/expr/code/lvalue'

module ExecuteController
  include LValueExpr

  def init_Controller(globals, initial, args=nil)
    globals.each {|g| execute(g, args)}
    args[:env]['CURRENT_STATE'] = initial
  end

  def execute_Controller(args=nil)
    execute(args[:env]['CURRENT_STATE'], args)
  end

  def execute_State(commands, transitions, args=nil)
    #test conditions BEFORE executing current state!!!
    moved = transitions.detect do |trans|
      execute(trans, args)
    end
    if !moved
      commands.each do |c|
        execute(c, args)
      end
    end
  end

  def execute_Transition(guard, target, args=nil)
    if self.eval(guard, args)
      args[:env]['CURRENT_STATE'] = target
      puts "Moving to state #{args[:env]['CURRENT_STATE']}"
      true
    else
      false
    end
  end

  def execute_Assign(var, val, args=nil)
    lvalue(var, args).value = self.eval(val, args)
  end

  def execute_TurnSplitter(splitter, percent, args=nil)
    @piping.turn_splitter(splitter, percent)
  end
end

class Controller

  include ExecuteController

  def initialize(piping, control)
    #piping is the interface to the state of the pipes. connects either to a simulator or hardware
    #state is the current state of the controller, used to store global runtime variables
    @piping = piping
    @state = {}
    @control = Loader.load(control)
    @env = ControlEnv.new(@piping, @state)
    init(@control, :env=>@env)
  end

  #environment to execute the controller in
  # similar to a normal environment except for the lookup
  # lookup order: local > piping > globals
  class ControlEnv < Hash
    def initialize(piping, globals)
      @piping = piping
      @globals = globals
    end

    def [](k)
      if @piping.sensor_names.include? k
        @piping.get_reading(k)
      elsif @piping.control_names.include? k
        @piping.get_control(k)
      else
        super
      end
    end

    def []=(k,v)
      if @piping.control_names.include? k
        @piping.set_control_value(k, v)
      else
        super
      end
    end
  end

  def run
    execute(@control, {:env=>@env})
  end

  def current_state
    @env['CURRENT_STATE']
  end
end

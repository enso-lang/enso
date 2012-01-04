=begin
=end


module ExecuteController
  include LValueExpr

  def init_Controller(globals, states, args=nil)
    globals.each do |g| execute(g)
  end

  def execute_Controller(globals, states, args=nil)
    execute(states[args[:env]['CURRENT_STATE']], args)
  end
s
  def execute_State(commands, transitions, args=nil)
    #test conditions BEFORE executing current state!!!
    moved = transitions.detect do |trans|

    end
    if !moved
      commands.each do |c|
        execute(commands, args)
      end
    end
  end

  def execute_Transition(guard, target, args=nil)
    if eval(guard)
      args[:env]['CURRENT_STATE'] = target
      true
    else
      false
    end
  end

  def execute_Assign(var, val, args=nil)
    lvalue(var, args).value = eval(val, args)
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
  end

  #environment to execute the controller in
  # similar to a normal environment except for the lookup
  # lookup order: local > piping > globals
  class ControlEnv
    def initialize(piping, globals)
      @hash = {}
      @piping = piping
      @globals = globals
    end

    def [](k)
      if @hash.has_key? k
        @hash[k]
      elsif @piping.sensor_names.include? k
        @piping.get_reading(k)
      elsif @globals.has_key? k
        @globals[k]
      else
        raise "No such variable #{k} in current environment"
      end
    end

    def []=(k,v)
      if @hash.has_key? k
        @hash[k] = v
      elsif @piping.control_names.include? k
        @piping.set_control(k, v)
      elsif @globals.has_key? k
        @globals[k]
      else
        raise "No such variable #{k} in current environment"
      end
    end
  end

  def run
    execute(@control, :env=>ControlEnv.new(@piping, @state))
  end
end

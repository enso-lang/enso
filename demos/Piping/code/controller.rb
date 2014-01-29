require 'core/semantics/code/interpreter'
require 'core/expr/code/lvalue'
require 'core/expr/code/env'
require 'core/expr/code/impl'
require '../demos/Piping/code/control-env'
require '../demos/Piping/code/controller-interp'

class Controller

  attr_reader :current

  def initialize(piping, control)
    #piping is the interface to the state of the pipes. connects either to a simulator or hardware
    #state is the current state of the controller, used to store global runtime variables
    @piping = piping
    @control = control
    @current = Variable.new("curr", @control.initial.name)
    @env = Env::HashEnv.new(current_state: @current).set_parent ControlEnv.new(@piping).set_parent({})

    @interp = Interpreter(ExecuteController)
    @interp.init(@control, env: @env)
  end

  def run
    @interp.execute(@control, env: @env, piping: @piping, control: @control)
  end
end

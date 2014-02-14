require 'core/semantics/code/interpreter'
require 'core/expr/code/eval'
require 'core/expr/code/lvalue'
require 'core/expr/code/env'

module ControllerInterpreter
  module RunController
    include Eval::EvalExpr
    include Lvalue::LValueExpr
    include Interpreter::Dispatcher

    def run(obj)
      dispatch_obj(:run, obj)
    end

    def run_Controller(obj)
      if not @D.include? :current or @D[:current].nil?
        obj.globals.each do |g|
          run(g)
        end
        new = obj.initial.name
      else
        new = run(obj.states[@D[:current]])
        new
      end
    end

    def run_State(obj)
      #test conditions BEFORE executing current state!!!
      trans = obj.transitions.detect do |trans|
        run(trans)
      end
      if !trans
        obj.commands.each do |c|
          run(c)
        end
        new = obj
      else
        new = trans.target
      end
      (new || obj).name
    end

    def run_Transition(obj)
      if eval(obj.guard)
        obj.target
      else
        nil
      end
    end

    def run_Assign(obj)
      tgt = lvalue(obj.var)
      val = eval(obj.val)
      tgt.value = val
    end

    def run_TurnSplitter(obj)
      @D[:env][obj.splitter].position = [[obj.percent, 1.0].min, 0.0].max
    end

  end

  class RunControllerC
    include RunController
  end
end

class Controller

  class ControllerState
    attr_accessor :current, :env
  end

  class ControlEnv
    include Env::BaseEnv
    def initialize(piping)
      @piping = piping
    end
    def has_key?(key)
      if @piping.sensors.has_key? key
        true
      elsif @piping.elements.has_key? key
        true
      else
        @parent.nil? ? nil : @parent.has_key?(key)
      end
    end
    def [](key)
      if @piping.sensors.has_key? key
        @piping.sensors[key]
      elsif @piping.elements.has_key? key
        @piping.elements[key]
      else
        @parent.nil? ? nil : @parent[key]
      end
    end
    def []=(key, value)
      if @piping.elements.has_key? key
        @piping.elements[key] = value
      else
        @parent[key] = value
      end
    end
    def each(&block)
      @piping.sensors.each do |s|
        yield s.name, s
      end
      @piping.elements.each do |e|
        yield e.name, e
      end
      @parent.each &block unless @parent.nil?
    end
  end

  def initialize(controller, piping)
    @sm = controller
    @interp = ControllerInterpreter::RunControllerC.new
    @state = ControllerState.new
    @state.env = Env::HashEnv.new({}, ControlEnv.new(piping))
    @interp.dynamic_bind env: @state.env do
      @state.current = @interp.run(@sm)
    end
  end

  def run
    @interp.dynamic_bind current: @state.current, env: @state.env do
      @state.current = @interp.run(@sm)
    end
  end

  def current_state
    @state.current
  end
end

if __FILE__ == $0 then
  require 'core/system/load/load'
  require 'core/semantics/interpreters/debug'

  class ControllerInterpreter::RunControllerC
    include Debug::Debug
    def run(obj)
      wrap(:run, :debug, obj)
    end
    def eval(obj)
      wrap(:eval, :debug, obj)
    end
  end

  name = 'boiler'

  Cache.clean("#{name}.controller")

  grammar = Load::load('piping.grammar')
  schema = Load::load('piping-sim.schema')
  control = Load::load("#{name}.controller")
  pipes = Load::load_with_models("#{name}.piping", grammar, schema)
  controller = Controller.new(control, pipes)

  while true
    controller.run
    puts controller.current_state
    sleep 2
  end
end



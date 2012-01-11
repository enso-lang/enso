require 'applications/Piping/code/simulator'
require 'applications/Piping/code/controller'
require 'applications/Piping/code/piping'
require 'core/system/load/load'
require 'core/schema/code/factory2'

class PipingSystem

  attr_reader :piping, :control, :controller, :sim
  
  def initialize(name)
    grammar = Loader.load('piping.grammar')
    schema = Loader.load('piping-sim.schema')
    @piping = Loader.load_with_models("#{name}.piping", grammar, schema)
    @control = Loader.load("#{name}.controller")
    @controller = Controller.new(SimulatorPiping.new(@piping), control)
    @sim = Simulator.new(@piping)
  end

  def run
    #some kind of virtual clock
    time = 0
    loop do
      sleep(1); time+=1
      @controller.run
      @sim.tick
      yield time
    end
  end
end

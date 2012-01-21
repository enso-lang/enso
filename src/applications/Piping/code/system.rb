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

  def run(time)
      @controller.run
      @sim.tick
      pump = @piping.elements['Pump']
      burner = @piping.elements['Burner']
      boiler = @piping.elements['Boiler']
      rad = @piping.elements['Radiator']
      valve = @piping.elements['Valve']
      bsensor = @piping.sensors['Boiler_Temp']
      rsensor = @piping.sensors['Radiator_Temp']
      puts "************************"
      puts "After #{time} sec:"
      puts "In #{@controller.current_state}"
      puts "  Burner at #{burner.temperature}"
      puts "  Boiler at #{boiler.temperature} (desired: #{bsensor.user})"
      puts "  Radiator at #{rad.temperature} (desired: #{rsensor.user})"
      puts "  Valve position #{valve.position}"
      puts "************************"
      yield time
  end
end

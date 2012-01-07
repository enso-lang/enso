require 'applications/Piping/code/simulator'
require 'applications/Piping/code/controller'
require 'applications/Piping/code/piping'
require 'core/system/load/load'
require 'core/schema/code/factory2'

class PipingSystem

  attr_reader :piping, :controller, :sim
  
  def initialize(name)
    grammar = Loader.load('piping.grammar')
    schema = Loader.load('piping-sim.schema')
    @piping = Loader.load_with_models("#{name}.piping", grammar, schema)    
    
    #initialize things
    @piping.elements['Pump'].flow = 0.05
    @piping.elements['Valve'].position = 0.5
    @piping.elements.each do |elem|
      begin; setPipe elem.input; rescue; end
      begin; setPipe elem.output; rescue; end
      begin; setPipe elem.left; rescue; end
      begin; setPipe elem.right; rescue; end
      begin
        elem.pipes.each do |p|
          setPipe p
        end
      rescue
      end
    end
    @controller = Controller.new(SimulatorPiping.new(@piping), "#{name}.controller")
    @sim = Simulator.new(@piping)
  end

  def setPipe(p)
    p.diameter = 0.1
    p.length = 10
    p.temperature = 50
    p.pressure = 0
  end

  def test_system
    #some kind of virtual clock
    loop do
      @controller.run
      @sim.tick
      yield
    end
  end
  
  def test_simulator 
    @sim = Simulator.new(@piping)
    @sim.tick
    Print.print(@piping)

    #now we start the pump
    @piping.elements['Pump'].flow = 0.1
    @piping.elements['Pump'].run = true
    @piping.elements['Burner'].gas_level = 80
    @piping.elements['Burner'].ignite = true
    (1..6).each do |i|
      puts "\n\n\n************************************************\n"
      puts "After #{i} tick"
      Print.print(@piping)
      @sim.tick
    end
  end

  def test_controller
    @controller = Controller.new(SimulatorPiping.new(@piping), 'boiler.controller')
    @controller.run
  end

end

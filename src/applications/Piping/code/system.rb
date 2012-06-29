require 'applications/Piping/code/simulator'
require 'applications/Piping/code/controller'
require 'core/system/load/load'
require 'core/schema/code/factory'

class PipingSystem

  attr_reader :piping, :control, :sim, :controller
  
  def initialize(name)
    grammar = Loader.load('piping.grammar')
    schema = Loader.load('piping-sim.schema')
    @piping = Loader.load_with_models("#{name}.piping", grammar, schema)
    @control = Loader.load("#{name}.controller")
    @control.current = @control.initial
    @controller = Controller.new(@piping, @control)
    @sim = Simulator.new(@piping)
    @time = 0
  end

  def run(time)
      @time += time
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
      puts "After #{@time} sec:"
      puts "In #{@control.current}"
      puts "  Burner at #{burner.temperature}"
      puts "  Boiler at #{boiler.temperature} (desired: #{bsensor.user})"
      puts "  Radiator at #{rad.temperature} (desired: #{rsensor.user})"
      puts "  Valve position #{valve.position}"
      puts "************************"
      yield
  end
end

if __FILE__ == $0 then
  time=0
  st = PipingSystem.new 'boiler'
  st.piping.sensors['Boiler_Temp'].user = 100
  while true
    sleep(1)
    time+=1
    st.run time do |time|
      puts "TICK after #{time} seconds: at state #{st.control.current.name}"
    end
  end
end

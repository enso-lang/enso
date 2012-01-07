require 'applications/Piping/code/simulator'
require 'applications/Piping/code/controller'
require 'applications/Piping/code/piping'
require 'core/system/load/load'
require 'core/schema/code/factory2'

class SimulatorTest

  def setup
    @pipes = Loader.load('boiler.piping')

    @piping = Copy(ManagedData::Factory.new(Loader.load('piping-sim.schema')), @pipes)
    @piping.elements['Pump'].flow = 0.05
    @piping.elements['Valve'].position = 0.5
    @piping.elements['Radiator'].temperature = 50
    @piping.elements['Return'].inputs.each {|p| p.output = @piping.elements['Return']}
    @piping.elements.each do |elem|
      begin
        elem.input.diameter = 0.1
        elem.input.length = 10
        elem.input.temperature = 50
        elem.input.pressure = 0
      rescue
      end
      begin
        elem.output.diameter = 0.1
        elem.output.length = 10
        elem.output.temperature = 50
        elem.output.pressure = 0
      rescue
      end
      begin
        elem.left.diameter = 0.1
        elem.left.length = 10
        elem.left.temperature = 50
        elem.left.pressure = 0
      rescue
      end
      begin
        elem.right.diameter = 0.1
        elem.right.length = 10
        elem.right.temperature = 50
        elem.right.pressure = 0
      rescue
      end
      begin
        elem.pipes.each do |p|
          p.diameter = 0.1
          p.length = 10
          p.temperature = 50
          p.pressure = 0
        end
      rescue
      end
    end
  end

  def test_system
    sim_interval = 1
    sim_display_interval = 3
    controller_interval = 1

    @sim = Simulator.new(@piping)
    @controller = Controller.new(SimulatorPiping.new(@piping), 'boiler.controller')

    #some kind of virtual clock
    curr = [controller_interval, sim_interval, sim_display_interval]
    count = 1
    while count<=13
      time = curr.min
      if curr[0] == time
        curr[0] = controller_interval
        @controller.run
      else
        curr[0] -= time
      end

      if curr[1] == time
        curr[1] = sim_interval
        @sim.tick
      else
        curr[1] -= time
      end

      if curr[2] == time
        curr[2] = sim_display_interval
        pump = @piping.elements['Pump']
        burner = @piping.elements['Burner']
        boiler = @piping.elements['Boiler']
        rad = @piping.elements['Radiator']
        valve = @piping.elements['Valve']
        puts "************************"
        puts "After #{count*sim_display_interval}sec:"
        puts "In #{@controller.current_state}"
        puts "  Pump is #{pump.run ? 'ON' : 'OFF'} at #{pump.flow}"
        puts "  Burner at #{burner.temperature}"
        puts "  Boiler at #{boiler.temperature}"
        puts "  Radiator at #{rad.temperature}"
        puts "  Valve position #{valve.position}"
        puts "************************"
        #Print.print(@piping)
        count += 1
      else
        curr[2] -= time
      end
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

st = SimulatorTest.new
st.setup
st.test_system

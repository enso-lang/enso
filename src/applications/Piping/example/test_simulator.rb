require 'test/unit'

require 'applications/Piping/code/simulator'
require 'core/system/load/load'

#class SimulatorTest < Test::Unit::TestCase

#  def test_run1

    fact = Factory.new(Loader.load('piping-sim.schema'))
    piping = Copy(fact, Loader.load('boiler.piping'))

=begin
    piping = fact.System

    source = fact.Source("Source")
    source.output = fact.Pipe
    source.output.diameter = 0.1
    source.output.length = 1.0

    burner = fact.Burner("Burner")
    burner.gas = source.output
    burner.output = fact.Pipe
    burner.output.diameter = 0.1
    burner.output.length = 1.0

    pump = fact.Pump("Pump")
    pump.output = fact.Pipe
    pump.input = burner.output
    pump.output.diameter = 0.1
    pump.output.length = 1.0

    valve = fact.Splitter("Valve")
    valve.left = fact.Pipe
    valve.right = fact.Pipe
    valve.input = pump.output
    valve.right.diameter = 0.1
    valve.right.length = 1.0
    valve.left.diameter = 0.1
    valve.left.length = 1.0

    boiler = fact.Vessel("Boiler")
    boiler.output = fact.Pipe
    boiler.input = valve.left
    boiler.output.diameter = 0.1
    boiler.output.length = 1.0

    radiator = fact.Radiator("Radiator")
    radiator.output = fact.Pipe
    radiator.output.diameter = 0.1
    radiator.output.length = 1.0
    radiator.input = valve.right

    retur = fact.Joint("Return")
    retur.output = fact.Pipe
    retur.output.diameter = 0.1
    retur.output.length = 1.0
    retur.pipes << boiler.output
    retur.pipes << radiator.output
    burner.input = retur.output

    piping.elements << source
    piping.elements << burner
    piping.elements << pump
    piping.elements << valve
    piping.elements << boiler
    piping.elements << radiator
    piping.elements << retur
=end
=begin
// inputs
   I: source water
   G: source \gas
// elements
   Burner: burner in=Return gas=G
   Pump: pump in=Burner
   Valve: splitter in=Pump
   Boiler: vessel in=Valve.left
   Radiator: radiator in=Valve.right
   RoomTemp: thermostat
   Return = Boiler + Radiator + I
// outputs
   furnace_output_temp: Temperature(Burner)
   boiler_temp: Temperature(Valve.left)
=end

    sim = Simulator.new(piping)
    sim.tick
    Print.print(piping)

    #now we start the pump
    piping.elements['Pump'].flow = 10
    piping.elements['Burner'].temperature = 80
    (1..10).each do |i|
      #puts "\n\n\n************************************************\n"
      #puts "After #{i} tick"
      sim.tick
    end
    Print.print(piping)

#  end
#end

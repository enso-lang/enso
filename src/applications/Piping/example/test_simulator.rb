#require 'test/unit'

require 'applications/Piping/code/simulator'
require 'core/system/load/load'

#class SimulatorTest < Test::Unit::TestCase

#  def test_run1

    fact = Factory.new(Loader.load('piping-sim.schema'))
    piping = Copy(fact, pipes = Loader.load('boiler.piping'))
    piping.elements.each do |elem|
      begin
        elem.input.connections << elem
      rescue
      end
      begin
        elem.output.connections << elem
      rescue
      end
      begin
        elem.left.connections << elem
      rescue
      end
      begin
        elem.right.connections << elem
      rescue
      end
      begin
        elem.pipes.each {|p| p.connections << elem}
      rescue
      end
    end

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

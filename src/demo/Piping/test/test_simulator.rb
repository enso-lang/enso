require 'test/unit'

require 'core/system/load/load'
require 'demo/Piping/code/simulator'

class PipingSimulatorTest < Test::Unit::TestCase

  def test_simulator
    name = 'boiler'

    grammar = Load::load('piping.grammar')
    schema = Load::load('piping-sim.schema')
    pipes = Load::load_with_models("#{name}.piping", grammar, schema)
    simulator = Simulator.new(pipes)

    pipes.elements['Pump'].run = true
    pipes.elements['Pump'].power = 200
    pipes.elements['Burner'].ignite = true
    pipes.elements['Burner'].temperature = 100

    #check that boiler is heated up a little after 10 ticks
    for i in 0..10
      simulator.run
    end
    temp_after_10 = pipes.elements['Boiler'].temperature
    assert(temp_after_10.between?(50, 80))

    #check that boiler fully heats up after 50 ticks
    for i in 0..40
      simulator.run
    end
    temp_after_50 = pipes.elements['Boiler'].temperature
    assert(temp_after_50.between?(80, 100))
    assert(temp_after_50 > temp_after_10)

    #cooldown
    pipes.elements['Burner'].ignite = false
    for i in 0..100
      simulator.run
    end
    temp_after_150 = pipes.elements['Boiler'].temperature
    assert(temp_after_150.between?(50, 60))
    assert(temp_after_150 < temp_after_50)
  end

end

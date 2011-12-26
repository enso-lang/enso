require 'test/unit'

require 'applications/Piping/code/simulator'

class SimulatorTest < Test::Unit::TestCase

  def test_run1
    sim = Simulator.new(boiler.piping)
    sim.tick
  end
end

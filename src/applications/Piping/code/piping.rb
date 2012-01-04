=begin

Abstract interface of the piping system that can be accessed by the controller.
This particular instance is attached to a simulator

=end

class PipingInterface
  def initialize(piping)
    @piping = piping
  end

  def sensor_names
    @piping.sensors.map{|s|s.name}
  end

  def get_reading_type(sensor_name)
    @piping.sensors[sensor_name].value
  end

  def control_name
    @piping.elements.map{|e|e.name}
  end
end

class SimulatorPiping < PipingInterface
  def initialize(piping)
    @piping = piping
  end

  def get_reading(sensor_name)
    @piping.sensors[sensor_name].value
  end

  def set_control(control_name, type, value)
  end
end

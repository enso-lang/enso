=begin

Abstract interface of the piping system that can be accessed by the controller.
This particular instance is attached to a simulator

=end

class PipingInterface
  def initialize(piping)
    @piping = piping
  end

  def start
    @piping.start
  end

  def sensor_names
    @piping.sensors.map{|s|s.name}
  end

  def get_reading_type(sensor_name)
    @piping.sensors[sensor_name].value
  end

  def control_names
    @piping.elements.map{|e|e.name}
  end
end

class SimulatorPiping < PipingInterface
  def initialize(piping)
    @piping = piping
  end

  def get_reading(sensor_name)
    sensor = @piping.sensors[sensor_name]
    sensor.attach[sensor.kind]
  end

  #FIXME: should not allow user to access control directly
  def get_control(control_name)
    @piping.elements[control_name]
  end

  def set_control_value(control_name, type, value)
    puts "Setting #{control_name}.#{type} to #{value}"
    @piping.elements[control_name][type] = value
  end

  def turn_splitter(splitter_name, value)
    splitter = @piping.elements[splitter_name]
    raise "Trying to turn a control #{valve_name} that is not a valve" if splitter.nil? or !splitter.Splitter?
    if value > 0
      splitter.position = [splitter.position + value / 100.0, 1.0].min
    else
      splitter.position = [splitter.position + value / 100.0, 0.0].max
    end
  end
end

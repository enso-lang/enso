
require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/grammar/render/layout'

require 'core/expr/code/dispatch'

=begin
NOTES:
- How to send commands from controller?
- How to display output? Log+sensor?
- Separate 'dynamic state' schema?
  - sometimes we need an 'old' and a 'new' state, and the static piping layout is unchanged
  - the piping editor is only concerned with the static layout
- Pipes vs Joints vs Splitters: Joints and splitters are 1-way?
- Sensors only attached to pipes? Not so in the example
- Proposed change: Pipes to have exactly two elements, and Sensor moved to a non element (special widget attached to pipes)

TODO:
- Temperature propagation via convection

Options for simulator-controller communication:
a. separate threads talking thru shared event list, ie producer consumer
b. after each tick, make a call to the controller. easier, but a little contrived (cant work in real life))

Useful Physics laws
- Ideal gas law: PV = nRT, P=Pressure, V=volume, n=amount of gas (moles), R=universal gas constant, T=temperature
  = Pressure and volume are inversely proportionate
- Bernoulli's law: v^2 + p/p0 = constant, where v=velocity of flow, p=pressure, p0=density of fluid
  = velocity is inversely dependent on pressure difference
- atmospheric pressure is 101.352 kPa
- Poiseuille's Equation Calculator: V = (pi * P * r^4) / (8 * n * L)
    V = Volume per Second
    P = Pressure Difference Between The Two Ends
    R = Internal Radius of the Tube
    n = Absolute Viscosity
    L = Total Length of the Tube

=end

ROOM_TEMP = 50
ERROR = 0.1

module CalcHeatFlow

  def CalcHeatFlow(elem, args)
    send("CalcHeatFlow_#{elem.schema_class.name}", elem, args[:oldpipe].elements[elem.name], args)
  end

  def CalcHeatFlow_Joint(elem, old, args)
    #funnel fluids from pipes into one pipe
    #total flow is conserved
    flow = set_pipe_flow(elem.output, args[:flowconst])
    temp = (old.inputs.inject(0) {|memo, p| memo + p.temperature * set_pipe_flow(p, args[:flowconst])} / flow).sigfig(3)
    transfer_heat(elem.output, flow, temp)
  end

  def CalcHeatFlow_Splitter(elem, old, args=nil)
    #shares fluids from one pipe to others
    #total flow is conserved
    #distribution is based on position of the splitting head
    elem.outputs.each do |p|
      transfer_heat(p, set_pipe_flow(p, args[:flowconst]), old.input.temperature)
    end
  end

  def CalcHeatFlow_Source(elem, old, args)
    #allows material to enter the system
    #pressure is assumed to be maintained by environment
    #since temperature
    elem.output.flow = 0
  end

  def CalcHeatFlow_Burner(elem, old, args)
    #burner heats up water that passes through it
    if elem.ignite
      elem.temperature = elem.gas_level
    else
      elem.temperature = old.input.temperature
    end
    flow = set_pipe_flow(elem.output, args[:flowconst])
    transfer_heat(elem.output, flow, elem.temperature)
  end

  def CalcHeatFlow_Radiator(elem, old, args)
    #radiator uses the heat from the passing water to heat the environment
    #assume the efficiency is 15%, ie 15% of the heat difference is transferred from the water to the environment
    #if the water passing through is cold, then this doubles up as a cooling system (?)
    flow = set_pipe_flow(elem.output, args[:flowconst])
    temp = (old.input.temperature - old.temperature) * 0.15
    elem.temperature = (old.temperature + temp).sigfig(3)
    new_temp = old.input.temperature - temp
    transfer_heat(elem.output, flow, new_temp)
  end

  def CalcHeatFlow_Vessel(elem, old, args=nil)
    #Allows material to fill up the vessel. Once filled it acts like a joint
    if false #elem.contents < elem.capacity

    else #behave like a joint
      elem.temperature = elem.input.temperature
      flow = set_pipe_flow(elem.output, args[:flowconst])
      transfer_heat(elem.output, flow, elem.temperature)
    end
  end

  def CalcHeatFlow_Pump(elem, old, args=nil)
    #raises the flow of the output pipe
    if elem.run = true
      flow = elem.output.flow = elem.flow
    else
      flow = elem.output.flow = set_pipe_flow(elem.output, args[:flowconst])
    end
    transfer_heat(elem.output, flow, old.input.temperature)
  end

  #transfer some amount of water from s1 to s2 based on connecting area and flow (based on pressure)
  def set_pipe_flow(p, flowconst)
    p.flow = ((p.in_pressure - p.out_pressure) / p.length * flowconst).sigfig(3)
  end

  def transfer_heat(pipe, flow, temperature)
    #simulate heat loss from water travelling in pipe
    temperature = flow > pipe.volume ? temperature : ((temperature * flow + pipe.temperature * (pipe.volume - flow)) / pipe.volume).sigfig(3)
    temp_diff = (temperature - ROOM_TEMP) * (0.98)
    temperature = ROOM_TEMP + temp_diff
    pipe.temperature = temperature
  end
end

class CalcPressure

  include WorkList

  #default element with one input and output
  def CalcPressure_?(fields, type, args=nil)
    input = fields['input']
    output = fields['output']
    #compute the pressure at this component based on the pressure at the other two ends of the two pipes
    num = input.in_pressure/input.length + output.out_pressure/output.length
    dem = 1.0/input.length + 1.0/output.length
    new_pressure = (num / dem).round(1)
    if (new_pressure-input.out_pressure).abs > ERROR
      input.out_pressure = output.in_pressure = new_pressure
      CalcPressure(input.input)
      CalcPressure(output.output)
    end
  end

  def CalcPressure_Source(output, args=nil)
    new_pressure = output.out_pressure
    if (new_pressure-output.in_pressure).abs > ERROR
      output.in_pressure = new_pressure
      CalcPressure(output.output)
    end
  end

  def CalcPressure_Joint(inputs, output, args=nil)
    num = inputs.inject(output.out_pressure/output.length) {|memo, p| memo + p.in_pressure/p.length}
    dem = inputs.inject(1.0/output.length) {|memo, p| memo + 1.0/p.length}
    new_pressure = (num / dem).round(1)
    if (new_pressure-output.in_pressure).abs > ERROR
      output.in_pressure = new_pressure
      inputs.each {|p| p.out_pressure = new_pressure}
      CalcPressure(output.output)
      inputs.each {|p| CalcPressure(p.input)}
    end
  end

  def CalcPressure_Splitter(position, input, left, right, args=nil)
    if position == 0
      if (right.in_pressure - right.out_pressure).abs > ERROR
        right.in_pressure = right.out_pressure
        CalcPressure(right.output)
      end
      num = input.in_pressure/input.length + left.out_pressure/left.length
      dem = 1.0/input.length + 1.0/left.length
      new_pressure = (num / dem).round(1)
      if (new_pressure - input.out_pressure).abs > ERROR
        input.out_pressure = left.in_pressure = new_pressure
        CalcPressure(input.input)
        CalcPressure(left.output)
      end
    elsif position == 1
      if (left.in_pressure - left.out_pressure).abs > ERROR
        left.in_pressure = left.out_pressure
        CalcPressure(left.output)
      end
      num = input.in_pressure/input.length + right.out_pressure/right.length
      dem = 1.0/input.length + 1.0/right.length
      new_pressure = (num / dem).round(1)
      if (new_pressure - input.out_pressure).abs > ERROR
        input.out_pressure = right.in_pressure = new_pressure
        CalcPressure(input.input)
        CalcPressure(right.output)
      end
    elsif position == 0.5
      num = input.in_pressure/input.length + left.out_pressure/left.length + right.out_pressure/right.length
      dem = 1.0/input.length + 1.0/left.length + 1.0/right.length
      new_pressure = (num / dem).round(1)
      if (new_pressure - input.out_pressure).abs > ERROR
        input.out_pressure = left.in_pressure = right.in_pressure = new_pressure
        CalcPressure(input.input)
        CalcPressure(right.output)
      end
    end
  end

  def CalcPressure_Pump(input, output, pressure, args=nil)
    if output.in_pressure != pressure
      output.in_pressure = pressure
      input.out_pressure = 0
      CalcPressure(output.output)
    end
  end
end

class Init
  include Map

  def Init_Pipe(args=nil)
    p = args[:obj]
    p.diameter = 0.1
    p.length = 10
    p.temperature = ROOM_TEMP
    p.in_pressure = 0
    p.out_pressure = 0
    p
  end

  def Init_Radiator(args=nil)
    args[:obj].temperature = ROOM_TEMP
  end

  def Init_Boiler(args=nil)
    args[:obj].temperature = ROOM_TEMP
  end

  def Init_?(fields, type, args=nil)
    args[:obj]
  end
end

class Float
  #utility function that rounds to significant figures
  def sigfig(digits)
    sprintf("%.#{digits - 1}e", self).to_f
  end
end

class Simulator

  include CalcHeatFlow

  def initialize(piping)
    @piping = piping
    #do initialization here by setting the default states of the pipes, etc
    Init.new.Init(@piping)
  end

    #will run continuously
  def execute
    while true
      tick
    end
  end

  #main step function. each step takes the current state and produces the next state
  #maintains a dirty bit on elements to know which elements are connected to pipes whose state have changed
  def tick
    pumps = @piping.elements.select {|o| o.Pump? }.values
    valves = @piping.elements.select {|o| o.Splitter? or o.Valve? }.values
    if !pumps.empty?
      CalcPressure.new(pumps+valves).CalcPressure
      p = pumps[0].output
      flowconst = pumps[0].flow / ((p.in_pressure - p.out_pressure) / p.length)
      oldpipe = Clone(@piping)
      @piping.elements.each {|e| CalcHeatFlow(e, :oldpipe=>oldpipe, :flowconst=>flowconst)}
    end
  end

end

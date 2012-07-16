
require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/grammar/render/layout'
require 'core/semantics/interpreters/fmap'
require 'core/semantics/interpreters/attributes'
require 'core/semantics/interpreters/debug'

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

  def CalcHeatFlow_Room(elem, old, args)
    elem.temperature = (args[:radiator].temperature - ROOM_TEMP) * 0.5 + ROOM_TEMP
  end

  def CalcHeatFlow_Burner(elem, old, args)
    #burner heats up water that passes through it
    if elem.ignite
      elem.gas_level = [elem.gas_level, ROOM_TEMP].max
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
    temp = (old.input.temperature - old.temperature) * 0.10
    elem.temperature = (old.temperature + temp).sigfig(3)
    new_temp = old.input.temperature - temp
    transfer_heat(elem.output, flow, new_temp)
  end

  def CalcHeatFlow_Vessel(elem, old, args=nil)
    #Allows material to fill up the vessel. Once filled it acts like a joint
    if false #elem.contents < elem.capacity
    else #behave like a joint
      flow = set_pipe_flow(elem.output, args[:flowconst])
      temp = (old.input.temperature - old.temperature) * 0.15
      elem.temperature = (old.temperature + temp).sigfig(3)
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
    temp_diff = (temperature - ROOM_TEMP) * (0.96)
    temperature = ROOM_TEMP + temp_diff
    pipe.temperature = temperature
  end
end

module CalcPressure

  operation :CalcPressure

  def CalcPressure_Pipe(input, output, args={})
    if args[:blocked_pipes].include? self
      @this.in_pressure = @this.out_pressure = output.CalcPressure(args)[:in]
    else
      @this.in_pressure = input.CalcPressure(args)[:out]
      @this.out_pressure = output.CalcPressure(args)[:in]
    end
    {:in=>@this.in_pressure, :out=>@this.out_pressure}
  end

  #default element with one input and output
  def CalcPressure_?(type, fields, args=nil)
    input = fields['input'].CalcPressure(args)
    output = fields['output'].CalcPressure(args)
    #compute the pressure at this component based on the pressure at the other two ends of the two pipes
    num = input[:in]/fields['input'].length + output[:out]/fields['output'].length
    dem = 1.0/fields['input'].length + 1.0/fields['output'].length
    new_pressure = (num / dem).round(1)
    {:in=>new_pressure, :out=>new_pressure}
  end

  def CalcPressure_Source(output, args=nil)
    new_pressure = output.CalcPressure(args)[:out]
    {:in=>new_pressure, :out=>new_pressure}
  end

  def CalcPressure_Joint(inputs, output, args=nil)
    outp = output.CalcPressure(args)
    num = inputs.inject(outp[:out]/output.length) {|memo, p| memo + p.CalcPressure(args)[:in]/p.length}
    dem = inputs.inject(1.0/output.length) {|memo, p| memo + 1.0/p.length}
    new_pressure = (num / dem).round(1)
    {:in=>new_pressure, :out=>new_pressure}
  end

  def CalcPressure_Splitter(position, input, left, right, args=nil)
    inp = input.CalcPressure(args)
    if position == 0
      args[:blocked_pipes] << right
      args[:blocked_pipes].delete(left)
      leftp = left.CalcPressure(args)
      num = inp[:in]/input.length + leftp[:out]/left.length
      dem = 1.0/input.length + 1.0/left.length
      new_pressure = (num / dem).round(1)
    elsif position == 1
      args[:blocked_pipes] << left
      args[:blocked_pipes].delete(right)
      rightp = left.CalcPressure(args)
      num = inp[:in]/input.length + rightp[:out]/right.length
      dem = 1.0/input.length + 1.0/right.length
      new_pressure = (num / dem).round(1)
    elsif position == 0.5
      leftp = left.CalcPressure(args)
      rightp = left.CalcPressure(args)
      num = inp[:in]/input.length + leftp[:out]/left.length + rightp[:out]/right.length
      dem = 1.0/input.length + 1.0/left.length + 1.0/right.length
      new_pressure = (num / dem).round(1)
    end
    {:in=>new_pressure, :out=>new_pressure}
  end

  def CalcPressure_Pump(input, output, args=nil)
    {:in=>0, :out=>100}
  end
  
  def default(obj)
    if obj.Pipe?
      {:in=>obj.in_pressure, :out=>obj.out_pressure}
    elsif obj.Source?
      {:in=>obj.output.in_pressure, :out=>obj.output.in_pressure}
    else
      {:in=>obj.inputs[0].out_pressure, :out=>obj.outputs[0].in_pressure}
    end
  end

  def __default_args; {:blocked_pipes=>[]}; end
end

module Init

  operation :Init

  def Init_Pipe(args=nil)
    p = @this
    p.diameter = 0.1 if p.diameter == 0
    p.length = 10 if p.length == 0
    p.temperature = ROOM_TEMP
    p.in_pressure = 0
    p.out_pressure = 0
    p
  end

  def Init_Radiator(args=nil)
    @this.temperature = ROOM_TEMP
  end

  def Init_Vessel(args=nil)
    @this.temperature = ROOM_TEMP
  end

  def Init_Sensor(args=nil)
    @this.user = ROOM_TEMP
  end

  def Init_?(fields, type, args=nil)
    @this
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
    Interpreter(Fmap.control(Init)).Init(@piping)
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
      Interpreter(AttrGrammar.control(CalcPressure)).CalcPressure(pumps[0].output)
      p = pumps[0].output
      flowconst = pumps[0].flow / ((p.in_pressure - p.out_pressure) / p.length)
      oldpipe = Clone(@piping)
      @piping.elements.each {|e| CalcHeatFlow(e, :oldpipe=>oldpipe, :flowconst=>flowconst, :radiator=>@piping.elements['Radiator'])}
    end
  end

end

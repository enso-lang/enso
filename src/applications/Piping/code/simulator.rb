
require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/grammar/render/layout'


=begin
NOTES:
- How to send commands from controller?
- How to display output? Log+sensor? Can the controller any state or only sensors?
- Separate 'dynamic state' schema?
  - sometimes we need an 'old' and a 'new' state, and the static piping layout is unchanged
  - the piping editor is only concerned with the static layout
- Pipes vs Joints vs Splitters: Joints and splitters are 1-way?
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
  = I am going to bastardize this into: xfer rate (mass/tick) = area * velocity
                                                              = (min(s1.diameter, s2.diameter)*3.14/4)
                                                                * sqrt(s1.pressure/s2.pressure - 1) * constant
  = this can never cause the pressure to move more than the final pressure, which is given by:
          (s1.volume*s1.pressure + s2.volume*s2.pressure) / s1.volume+s2.volume
  = atmospheric pressure is ~100kPa
=end

module Step
  def step(elem, *args)
    send("step_#{elem.schema_class.name}", *args)
  end

  def step_Joint(elem, new_elem)
    #transport fluids from pipes to other pipes
    #velocity is dependent on pressure difference
    #will never cause source pipes to have a lower pressure than output
    elem.pipes.each do |p|
      next unless p.pressure > elem.output.pressure
      transfer = ([p.diameter, elem.output.diameter].min *3.14/4) * sqrt(p.pressure/elem.output.pressure - 1) * 10
      next unless transfer > 1.0
      puts "#{transfer} amount of material flowed from #{p} to #{elem.output}"
      p1 = (p.pressure*p.volume - transfer) / p.volume
      p2 = (elem.output.pressure*elem.output.volume + transfer) / elem.output.volume
      if p1.pressure < p2.pressure
        p1=p2= (p.volume*p.pressure + s2.volume*s2.pressure) / s1.volume+s2.volume
      end
      p.pressure = p1
      elem.output.pressure = p2
      dirty_pipe(p)
      dirty_pipe(elem.output)
    end
  end

  def step_Source(elem, new_elem)
    #allows material to enter the system
    #pressure is assumed to be maintained by environment
    if elem.output.pressure != elem.pressure
      elem.output.pressure = elem.pressure
      dirty_pipe(elem.output)
    end
  end

  def step_Exhaust(elem, new_elem)
    #allows material to exit the system
    transfer = (input *3.14/4) * sqrt(input.pressure/100 - 1) * 10
    input.pressure = (input.pressure*input.volume - transfer) / input.volume
    dirty_pipe(elem.input)
  end

  def step_Burner(elem, new_elem)
  end

  def step_Radiator(elem, new_elem)
  end

  def step_Vessel(elem, new_elem)
    #Allows material to fill up the vessel. Once filled it acts like a joint
    if elem.contents < elem.capacity
      transfer = (input *3.14/4) * sqrt(input.pressure/100 - 1) * 10
      input.pressure = (input.pressure*input.volume - transfer) / input.volume
      elem.contents += transfer
      dirty_pipe(input)
    else #behave like a joint
      s1 = elem.input
      s2 = elem.output
      transfer = ([s1.diameter, s2.diameter].min *3.14/4) * sqrt(s1.pressure/s2.pressure - 1) * 10
      if transfer > 1.0
        puts "#{transfer} amount of material flowed from #{s1} to #{s2}"
        p1 = (s1.pressure*s1.volume - transfer) / s1.volume
        p1 = (s2.pressure*s2.volume + transfer) / s2.volume
        if p1.pressure < p2.pressure
          p1=p2= (p.volume*p.pressure + s2.volume*s2.pressure) / s1.volume+s2.volume
        end
        s1.pressure = p1
        s2.pressure = p2
        dirty_pipe(s1)
        dirty_pipe(s2)
      end
    end
  end

  def step_Valve(elem, new_elem)
  end

  def step_Thermostat(elem, new_elem)
  end

  def step_Splitter(elem, new_elem)
    #transport fluids from pipes to other pipes
    #velocity is dependent on pressure difference
    #will never cause source pipes to have a lower pressure than output
    elem.pipes.each do |p|
      next unless p.pressure < elem.output.pressure
      transfer = ([p.diameter, elem.output.diameter].min *3.14/4) * sqrt(p.pressure/elem.output.pressure - 1) * 10
      next unless transfer < 1.0
      puts "#{transfer} amount of material flowed from #{elem.input} to #{p}"
      p1 = (p.pressure*p.volume + transfer) / p.volume
      p2 = (elem.output.pressure*elem.output.volume - transfer) / elem.output.volume
      if p1.pressure > p2.pressure
        p1=p2= (p.volume*p.pressure + s2.volume*s2.pressure) / s1.volume+s2.volume
      end
      p.pressure = p1
      elem.output.pressure = p2
      dirty_pipe(p)
      dirty_pipe(elem.output)
    end
  end

  def step_Pump(elem, new_elem)

  end
end

class Simulator

  include Step

  def initialize(piping_file)
    @piping = Loader.load(piping_file)
  end

  #will run continuously
  def run
    while true
      tick
    end
  end

  #main step function. each step takes the current state and produces the next state
  #maintains a dirty bit on elements to know which elements are connected to pipes whose state have changed
  def tick
    dirty = @dirty_elems.clone
    @dirty_elems = []
    dirty.each do |e|
      step(e)
    end
  end

  def dirty_pipe(p)
    p.connections.each do |e|
      @dirty_elems << e
    end
  end
end

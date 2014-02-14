
require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/grammar/render/layout'
require 'core/semantics/interpreters/debug'

=begin
The SCIENCE!
------------
* Calculating pressure:

Using kirchoff's law:
At any point (elem), sum of (input pressure delta / input pipe length) = sum of (output pressure delta / output pipe length)

hence,
  sum( (Pn-P)/Ln ) = 0, where P is pressure at the opposite end of the pipe (Pn-P is negative for out pipes), 
                              L is length, and 
                              sum means sum over all pipes 1..n
  sum( Pn/Ln - P/Ln) = 0
  sum(Pn/Ln) - P * sum(1/Ln) = 0
  P = sum(Pn/Ln) / sum(1/Ln)

* Calculating heat flow:

at each element, compute
  - how much incoming water. flow is in length dimensions
  - at what temperature (based on flow of incoming pipes)

transfer to output pipes
  - each pipe receives water based on its flow
  - assume temperatures mix perfectly

=end

ROOM_TEMP = 50
ERROR = 0.1
FLOW_CONST = 1
COOLING_CONST = 0.03

module SimulatorInterpreter
  module RunSimulator
    include Eval::EvalExpr
    include Lvalue::LValueExpr
    include Interpreter::Dispatcher

    def run(obj)
      dispatch_obj(:run, obj)
    end

    def calcPressure(obj)
      dispatch_obj(:calcPressure, obj)
    end

    def calcHeat(obj)
      dispatch_obj(:calcHeat, obj)
    end

    def run_System(obj)
      dynamic_bind workqueue: [] do
        # add just the pump to the workqueue
        obj.elements.each do |elem|
          if elem.Pump? or elem.Splitter?
            enqueue(elem)
          end
        end
        # run queue to calculate pressure
        while not done()
          calcPressure(dequeue())
        end
      end
      # calculate heat and flow based on pressure differences
      obj.elements.each do |elem|
        calcHeat(elem)
      end
    end

    def enqueue(elem)
      if not @D[:workqueue].include? elem and not elem.nil?
        @D[:workqueue].push(elem)
      end
    end
    def dequeue()
      @D[:workqueue].shift
    end
    def done()
      @D[:workqueue].empty?
    end

    def approx(float1, float2)
      (float1 - float2).abs < ERROR
    end

    #check if neighboring elems need to be added to workqueue
    #only works for elements with one in and one out pipe
    def pressurize_pipes(elem, new_in, new_out)
      elem.inputs.each do |inpipe|
        if not approx(inpipe.out_pressure, new_in)
          inpipe.out_pressure = new_in
          enqueue(inpipe.input)
        end
      end
      elem.outputs.each do |outpipe|
        if not approx(outpipe.in_pressure, new_out)
          outpipe.in_pressure = new_out
          enqueue(outpipe.output)
        end
      end
    end

    def calcPressure_Pump(elem)
      if elem.run
=begin
        # when running, exert a pressure difference between the two ends
        # based on pump power (pressure) and pressure at in/out pipes
        # basically same as normal computation except that in pressure 
        # pretends to be higher by power units
        num = elem.inputs.inject(0) {|memo, p| memo + (p.in_pressure+elem.power) / p.length} \
            + elem.outputs.inject(0) {|memo, p| memo + p.out_pressure / p.length}
        dem = elem.inputs.inject(0) {|memo, p| memo + 1.0 / p.length} \
            + elem.outputs.inject(0) {|memo, p| memo + 1.0 / p.length}
        new_out = (num / dem).round(1)
        new_in = new_out - elem.power
        pressurize_pipes(elem, new_in, new_out)
=end
        #the code above is commented out for aesthetic purposes: I want 
        # pressure to only be positive numbers
        new_out = elem.power
        new_in = 0.0
        pressurize_pipes(elem, new_in, new_out)
      else
        # if not on then behave like normal element
        calcPressure_?(elem)
      end
    end

    def calcPressure_Splitter(splitter)
      if splitter.position == 0.5 #do the normal thing
        calcPressure_?(splitter)
      else 
        if splitter.position == 0.0 #turn left
          #left pipe behaves as the only pipe
          num = splitter.input.in_pressure / splitter.input.length \
              + splitter.outputs[0].out_pressure / splitter.outputs[0].length
          dem = 1.0 / splitter.input.length \
              + 1.0 / splitter.outputs[0].length
          new_in = new_out0 = (num / dem).round(1)
          #right pipe behaves like it's sealed (ie pressure = other side)
          new_out1 = splitter.outputs[1].out_pressure
        elsif splitter.position == 1.0 #turn right
          #right pipe behaves as the only pipe
          num = splitter.input.in_pressure / splitter.input.length \
              + splitter.outputs[1].out_pressure / splitter.outputs[1].length
          dem = 1.0 / splitter.input.length \
              + 1.0 / splitter.outputs[1].length
          new_in = new_out1 = (num / dem).round(1)
          #left pipe behaves like it's sealed (ie pressure = other side)
          new_out0 = splitter.outputs[0].out_pressure
        end
        if not approx(splitter.input.out_pressure, new_in)
          splitter.input.out_pressure = new_in
          enqueue(splitter.input.input)
        end
        if not approx(splitter.outputs[0].in_pressure, new_out0)
          splitter.outputs[0].in_pressure = new_out0
          enqueue(splitter.outputs[0].output)
        end
        if not approx(splitter.outputs[1].in_pressure, new_out1)
          splitter.outputs[1].in_pressure = new_out1
          enqueue(splitter.outputs[1].output)
        end
      end
    end

    def calcPressure_?(elem)
      num = elem.inputs.inject(0) {|memo, p| memo + p.in_pressure / p.length} \
          + elem.outputs.inject(0) {|memo, p| memo + p.out_pressure / p.length}
      dem = elem.inputs.inject(0) {|memo, p| memo + 1.0 / p.length} \
          + elem.outputs.inject(0) {|memo, p| memo + 1.0 / p.length}
      new_in = new_out = (num / dem).round(1)
      pressurize_pipes(elem, new_in, new_out)
    end

    def recv_heat(elem)
      # in_flow is how much water comes in
      # in_temp is how hot they are
      in_temp = 0
      in_flow = 0
      elem.inputs.each do |pipe|
        in_flow += flow = (pipe.in_pressure - pipe.out_pressure) / pipe.length * FLOW_CONST
        in_temp += pipe.temperature * flow
      end
      in_flow==0 ? 0 : in_temp / in_flow
    end

    def send_heat(elem, in_temp)
      # this hot water is distributed to the out pipes and their new temp is calculated
      # note: sum of flows for all inpipes = sum of flows of all outpipes
      elem.outputs.each do |pipe|
        flow = (pipe.in_pressure - pipe.out_pressure) / pipe.length * FLOW_CONST
        if flow > pipe.length
          pipe.temperature = in_temp
        else
          pipe.temperature = ((in_temp * flow + pipe.temperature * (pipe.length-flow)) / pipe.length).round(1)
        end
      end
    end

    def env_cooling(pipe)
      # finally, pipes suffer heat loss to the environment based on their surface area
      pipe.temperature = (pipe.temperature * (1.0-COOLING_CONST) + ROOM_TEMP * COOLING_CONST).round(1)
    end

    def calcHeat_Burner(elem)
      # similar to normal elements except heat output is temperature when turned on
      in_temp = recv_heat(elem)
      in_temp = [elem.temperature, in_temp].max if elem.ignite #cannot heat to lower temp than input
      send_heat(elem, in_temp)
      elem.outputs.each do |pipe|
        env_cooling(pipe)
      end
    end

    def calcHeat_Source(elem)
    end

    def calcHeat_Exhaust(elem)
    end

    def calcHeat_Vessel(elem)
      # right now same as radiator
      # temperature of radiator heated up by incoming pipes
      # but loses heat to the environment (which heats up the room)
      in_temp = recv_heat(elem)
      heating_rate = 0.20
      elem.temperature = in_temp * heating_rate + elem.temperature * (1-heating_rate)
      # cools slower than a normal pipe
      elem.temperature = (elem.temperature * (1.0-COOLING_CONST/3) + ROOM_TEMP * COOLING_CONST/3).round(1)
      in_temp = elem.temperature
      send_heat(elem, in_temp)
      elem.outputs.each do |pipe|
        env_cooling(pipe)
      end
    end

    def calcHeat_Radiator(elem)
      # temperature of radiator heated up by incoming pipes
      # but loses heat to the environment (which heats up the room)
      in_temp = recv_heat(elem)
      heating_rate = 0.20
      elem.temperature = in_temp * heating_rate + elem.temperature * (1-heating_rate)
      # cools slower than a normal pipe
      elem.temperature = (elem.temperature * (1.0-COOLING_CONST/3) + ROOM_TEMP * COOLING_CONST/3).round(1)
      in_temp = elem.temperature
      send_heat(elem, in_temp)
      elem.outputs.each do |pipe|
        env_cooling(pipe)
      end
    end

    def calcHeat_?(elem)
      in_temp = recv_heat(elem)
      send_heat(elem, in_temp)
      elem.outputs.each do |pipe|
        env_cooling(pipe)
      end
    end
  end

  class RunSimulatorC
    include RunSimulator
  end
end

class Simulator

  def initialize(piping)
    @sm = piping
    # initial all pipes to be of the same length / diameter and temperature
    @sm.elements.each do |elem|
      elem.outputs.each do |pipe|
        pipe.temperature = ROOM_TEMP
        pipe.length = 10 #if pipe.length == 0
        pipe.diameter = 0.1 if pipe.diameter == 0
      end
      if elem.Temperatured?
        elem.temperature = ROOM_TEMP
      end
      if elem.Splitter?
        elem.position = 0.5
      end
    end
    @sm.sensors.each do |sensor|
      sensor.user = ROOM_TEMP
    end

    @interp = SimulatorInterpreter::RunSimulatorC.new
  end

  def run
    @interp.run(@sm)
  end

  def display_state
    # display current state
    puts "\nCurrent state"
    @sm.elements.each do |elem|
      begin
      print "#{elem.name[0..6]}"
      if elem.Attachable? and not elem.sensor.nil?
        print "\tT:#{elem.output.temperature} -> #{elem.sensor.user}"
      elsif elem.Splitter?
        print "\tT:#{elem.output.temperature} #{elem.position < 0.5 ? "<--" : (elem.position > 0.5 ? "-->" : "-O-")}"
      else
        print "\tT:#{elem.output.temperature}\t"
      end
      if elem.Pump?
        print "\tP:#{elem.input.out_pressure}/#{elem.output.in_pressure} (#{elem.output.in_pressure-elem.input.out_pressure})"
      else
        print "\tP:#{elem.output.in_pressure}"
      end
      puts
      rescue; end
    end
    puts
  end
end

if __FILE__ == $0 then
  require 'core/system/load/load'
  require 'core/semantics/interpreters/debug'

  class SimulatorInterpreter::RunSimulatorC
    include Debug::Debug
    def run(obj)
      wrap(:run, :debug, obj)
    end
    def calcPressure(obj)
      wrap(:calcPressure, :debug, obj)
    end
  end

  name = 'boiler'

  Cache.clean("#{name}.piping-sim")

  grammar = Load::load('piping.grammar')
  schema = Load::load('piping-sim.schema')
  pipes = Load::load_with_models("#{name}.piping", grammar, schema)
  simulator = Simulator.new(pipes)

  pipes.elements['Pump'].run = true
  pipes.elements['Pump'].power = 200
  pipes.elements['Burner'].ignite = true
  pipes.elements['Burner'].temperature = 100

  time = 0
  while true
    puts "\n========================="
    puts "TIME: #{time+=1}\n"
    simulator.run
    simulator.display_state
    sleep 1
  end
end



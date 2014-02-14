require '../demos/Piping/code/simulator'
require '../demos/Piping/code/controller'

name = 'boiler'

Cache.clean("#{name}.piping-sim")
Cache.clean("#{name}.controller")

grammar = Load::load('piping.grammar')
schema = Load::load('piping-sim.schema')
pipes = Load::load_with_models("#{name}.piping", grammar, schema)
simulator = Simulator.new(pipes)
control = Load::load("#{name}.controller")
controller = Controller.new(control, pipes)

pipes.sensors['Boiler_Temp'].user = 100
pipes.sensors['Radiator_Temp'].user = 60

time = 0
while true
  #seed user preferences changing
  if rand(100) < 5
    pipes.sensors['Boiler_Temp'].user = rand(100)+30
    pipes.sensors['Radiator_Temp'].user = rand(100)+30
    puts
    puts "** User wants boiler at #{pipes.sensors['Boiler_Temp'].user}! Radiator at #{pipes.sensors['Radiator_Temp'].user}! **"
    puts
  end
  puts "\n========================="
  puts "TIME: #{time+=1}\n"
  simulator.run
  controller.run
  puts controller.current_state
  simulator.display_state
  sleep 1
end


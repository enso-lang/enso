
# view the piping diagram
arch -i386 ruby -I. core/diagram/code/stencil.rb applications/Piping/example/boiler.piping

# test the simulator
ruby -I. applications/Piping/code/test_simulator.rb

# run the visualization
arch -i386 ruby -I. applications/Piping/code/visualize.rb
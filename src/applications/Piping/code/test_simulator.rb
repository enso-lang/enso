require 'applications/Piping/code/system'

st = PipingSystem.new 'boiler'
count = 0
st.run do
  #return if count > 20
  if count % 3 == 0
    pump = st.piping.elements['Pump']
    burner = st.piping.elements['Burner']
    boiler = st.piping.elements['Boiler']
    rad = st.piping.elements['Radiator']
    valve = st.piping.elements['Valve']
    puts "************************"
    puts "After #{count} sec:"
    puts "In #{st.controller.current_state}"
    puts "  Pump is #{pump.run ? 'ON' : 'OFF'} at #{pump.flow}"
    puts "  Burner at #{burner.temperature}"
    puts "  Boiler at #{boiler.temperature} (desired: #{boiler.user_temp})"
    puts "  Radiator at #{rad.temperature} (desired: #{rad.user_temp})"
    puts "  Valve position #{valve.position}"
    puts "************************"
    #Print.print(@piping)
  end
  count += 1
end

require 'applications/Piping/code/system'

st = PipingSystem.new 'boiler'
while true
  sleep(0.1)
  #seed user preferences changing
  if rand(100) < 5
    st.piping.sensors['Boiler_Temp'].user = rand(100)+30
    st.piping.sensors['Radiator_Temp'].user = rand(100)+30
  end
  st.run 1 do
  end
end

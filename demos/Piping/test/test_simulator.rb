require '../demos/Piping/code/system'

$n = 100
st = PipingSystem.new 'boiler'
st.piping.sensors['Boiler_Temp'].user = rand(100)+30
st.piping.sensors['Radiator_Temp'].user = rand(100)+30
$time = Time.now
$n.times do
  #seed user preferences changing
  if rand(100) < 5
    st.piping.sensors['Boiler_Temp'].user = rand(100)+30
    st.piping.sensors['Radiator_Temp'].user = rand(100)+30
  end
  st.run 1 do
  end
end
puts "Elapsed time = #{Time.now-$time}s"

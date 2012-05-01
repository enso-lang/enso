require 'applications/Piping/code/system'
require 'core/diagram/code/stencil'

Wx::App.run do
  st = PipingSystem.new 'boiler'

  win_piping = StencilFrame.new
  win_piping.setup 'piping-sim', st.piping

  win_control = StencilFrame.new
  win_control.setup 'controller', st.control

  win_piping.show
  win_control.show

  gs = Loader.load("stencil.grammar")
  Print.print(gs)

  time = 0
  Wx::Timer.every(1000) do
    time+=1
    st.run time do |time|
      puts "TICK after #{time} seconds: at state #{st.control.current.name}"
      win_control.refresh
      win_piping.refresh
    end
  end
end

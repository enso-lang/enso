require 'applications/Piping/code/system'
require 'core/diagram/code/stencil'

Wx::App.run do
  st = PipingSystem.new 'boiler'

  win_piping = StencilFrame.new
  win_piping.setup 'piping-sim', st.piping

  win_control = StencilFrame.new
  win_control.setup 'controller', st.control

  Thread.new do
    sleep 1
    st.run do |time|
      puts "TICK after #{time} seconds: at state #{st.control.current.name}"
      win_control.refresh
      win_piping.refresh
    end
  end

  win_piping.show
  win_control.show
end


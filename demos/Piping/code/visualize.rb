require '../demos/Piping/code/system'
require 'core/diagram/code/stencil'

Wx::App.run do
  $st = PipingSystem.new 'boiler'

  win_piping = StencilFrame.new
  win_piping.setup 'piping-sim', $st.piping

  win_control = StencilFrame.new
  win_control.setup 'controller', $st.control

  win_piping.show
  win_control.show

  time = 1
  Wx::Timer.every(2000) do
    $st.run time do
      win_control.refresh
      win_piping.refresh
    end
  end
end

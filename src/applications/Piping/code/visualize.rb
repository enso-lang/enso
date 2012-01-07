require 'applications/Piping/code/system'
require 'core/diagram/code/stencil'

Wx::App.run do
  st = PipingSystem.new 'boiler'

  win = StencilFrame.new
  win.setup 'piping-sim', st.piping

  Thread.new do
    sleep 1
    st.test_system do |time|
      win.refresh
    end
  end
  win.show 
end


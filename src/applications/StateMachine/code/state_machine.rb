
require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/diagram/code/stencil'

def run_state_machine(sm)

Wx::App.run do

  current = sm.start
  puts "#{current.name}"
  
  win_piping = StencilFrame.new
  win_piping.setup 'state_machine', sm
  win_piping.show

  Wx::Timer.every(1000) do
    win_piping.refresh

    gets
    input = $_.strip
    current.out.each do |trans|
      if trans.event == input
        current = trans.to
        break
      end
    end
    puts "#{current.name}"
  end
=begin
  while gets
    input = $_.strip
    current.out.each do |trans|
      if trans.event == input
        current = trans.to
        break
      end
    end
    puts "#{current.name}"
  end
=end
end

end


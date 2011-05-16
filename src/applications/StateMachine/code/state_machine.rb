
require 'core/system/load/load'
require 'core/schema/tools/print'

def StateMachine_Interp(sm)
  current = sm.start
  puts "#{current.name}"
  while gets
    input = $_.strip
    current.out.each do |trans|
      if trans.event == input
        current = trans.to
      end
    end
    puts "#{current.name}"
  end
end

sm = Loader.load("door.state_machine")
Print.print(sm)

StateMachine_Interp(sm)


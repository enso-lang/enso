
require 'core/system/load/load'
require 'core/schema/tools/print'

def run_state_machine(sm)
  current = sm.start
  puts "#{current.name}"
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
end


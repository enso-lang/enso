require 'core/system/load/load'
require 'core/schema/tools/print'

def run_state_machine(sm)
    current = sm.start
    puts "#{current.name}"
    while $stdin.gets
      input = $_.strip
      trans = current.out.find do |trans|
        trans.event == input
      end
      current = trans.to if trans
      puts "#{current.name}"
    end
end

sm = Load::load(ARGV[0])
run_state_machine(sm)
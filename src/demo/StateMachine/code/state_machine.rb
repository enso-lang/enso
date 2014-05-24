
require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/diagram/code/stencil'

def run_state_machine(sm)

  Wx::App.run do
  
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
end

if __FILE__ == $0
  sm = Load::load(ARGV[0])
  run_state_machine(sm)
end

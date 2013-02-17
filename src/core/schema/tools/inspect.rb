
require 'core/system/load/load'
require 'core/schema/tools/print'

if __FILE__ == $0 then
  if !ARGV[0] then
    $stderr << "Usage: inspect.rb <model>"
    exit!(1)
  end
  model = ARGV[0]
  m = Load::load(model)
  Print.print(m)
end

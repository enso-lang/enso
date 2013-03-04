require 'core/system/load/load'
require 'core/diagram/code/construct'
require 'core/diagram/code/render'

data_file = ARGV[0]
if data_file.nil?
  abort "usage: ruby test_stencil.rb <model>"
end
stencil_file = "#{data_file.split('.')[-1]}.stencil"

stencil = Load::load(stencil_file)
data = Load::load(data_file)
model = Construct::eval(stencil, data: data)

def render(diagram)
  html = Render::render(diagram)
  #puts html
  
  File.open('stencil.html', 'w+') do |file|
    file.syswrite(html)
  end
end
render(model)

require 'test/repl.rb'

Repl.run(data) do
  render(model)
  puts "Re-rendered page"
end

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

mm = {}
model = Construct::eval(stencil, data: data, modelmap: mm)
abort
Print.print(model)
mm.each do |k,v|
  puts "\n#{k} ->"
  Print.print(v)
end

def render(diagram, data)
  html = Render::render(diagram, data: data)
  #puts html
  
  File.open('stencil.html', 'w+') do |file|
    file.syswrite(html)
  end
end
render(model, data)

abort

require 'test/repl.rb'

Repl.run(model) do
  render(model, data)
  puts "Re-rendered page"
end

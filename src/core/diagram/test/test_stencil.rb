require 'core/system/load/load'
require 'core/diagram/code/construct'
require 'core/diagram/code/render'

stencil = Load::load('ql.stencil')
data = Load::load('income.ql')

diagram = Construct::eval(stencil, data: data)
Print.print(diagram)

html = Render::render(diagram)
#puts html

File.open('stencil.html', 'w+') do |file|
  file.syswrite(html)
end


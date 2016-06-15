require 'core/system/load/load'

data_file = ARGV[0]
if data_file.nil?
  abort "usage: ruby test_stencil.rb <model>"
end

Load::load("stencil.schema")
Load::load("diagram.schema")
Load::load("stencil.grammar")
Load::load("diagram.grammar")
Load::load("code.schema")
Load::load("code_js.grammar")

stencil_file = "#{data_file.split('.')[-1]}.stencil"
puts "STENCIL is #{stencil_file}"
stencil = Load::load(stencil_file)
data = Load::load(data_file)

Load::load("state_machine.stencil")

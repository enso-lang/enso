require 'core/system/load/load'

data_file = ARGV[0]
if data_file.nil?
#  abort "usage: ruby test_stencil.rb <model>"
  data_file = "housing.ql"
end
stencil_file = "#{data_file.split('.')[-1]}.stencil"

stencil = Load::load(stencil_file)
data = Load::load(data_file)



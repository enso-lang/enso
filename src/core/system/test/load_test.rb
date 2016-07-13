

require 'core/system/load/load'


ARGV.each do |a|
  #Load::Loader.load!(a)
  Load::load a
end

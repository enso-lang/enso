

require 'core/system/load/load'


ARGV.each do|a|
  Load::load a
end

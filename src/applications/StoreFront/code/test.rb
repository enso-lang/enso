

require 'core/system/load/load'


if __FILE__ == $0 then
  x = Loader.load('storefront.schema')
  print x
  puts
end

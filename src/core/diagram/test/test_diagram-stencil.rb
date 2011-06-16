

require 'core/diagram/code/stencil'
require 'core/system/load/load'
require 'core/schema/tools/print'


DsS = Loader.load('stencil.schema')
DsG = Loader.load('stencil.grammar')
SDs = Loader.load('simple.stencil')
Print.print(SDs)

#SDs = Loader.load('schema.stencil')

#Print.print(SDs)

s = StencilFrame.new(SDs, Load('schema.schema'))

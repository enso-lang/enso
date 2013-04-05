require 'core/system/load/load'
require 'core/diagram/code/traceval'

exp = Load::load('test2.impl')

src = {}
puts Traceval.eval(exp, env: {'x'=>22, 'lst'=>[1,2,3,4,5]}, factory: exp.factory, src: src, srctemp: {})

#puts src
#Print.print(exp)
Print.print(src[exp])



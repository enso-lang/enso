require 'core/system/load/load'
require 'core/semantics/interpreters/fmap'
require 'core/semantics/interpreters/debug'
require 'core/semantics/code/as-interp'

CacheXML.clean('expr1.expr')
expr = Load::load('expr1.expr')
Print.print(expr)

interp = Interpreter(Debug.wrap(Fmap.traverse(Interpreter.do(:plus1) do |obj|
  obj.val+=1 if obj.EIntConst?
end)))
interp.plus1(expr)

Print.print(expr)

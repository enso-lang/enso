require 'core/system/load/load'
require 'core/semantics/interpreters/fmap'
require 'core/semantics/interpreters/debug'

CacheXML.clean('expr1.expr')
expr = Load::load('expr1.expr')
Print::Print.print(expr)

module PlusOne
  operation :p1
  def p1_?(type, fields, args); end
  def p1_EIntConst(val)
    @this.val = val+1
  end
end

interp = Interpreter(Fmap.traverse(PlusOne))
interp.p1(expr)

Print::Print.print(expr)

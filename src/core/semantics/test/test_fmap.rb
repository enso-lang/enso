require 'core/system/load/load'
require 'core/semantics/interpreters/fmap'
require 'core/semantics/interpreters/debug'

CacheXML.clean('expr1.expr')
expr = Loader.load('expr1.expr')
Print.print(expr)

module PlusOne
  operation :p1
  def p1_?(type, fields, args={}); end
  def p1_EIntConst(val, args={})
    @this.val = val+1
  end
end

interp = Interpreter(Fmap.control(PlusOne))
interp.p1(expr)

Print.print(expr)
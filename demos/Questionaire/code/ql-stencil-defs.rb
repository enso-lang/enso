require 'core/diagram/code/construct'

def Eval(expr, elems)
  puts "\n\n\nI am here!!!\n\n\n"
  env = {}
  elems.each {|e| env += get_env(e)}
  puts "env=#{env}"
  Print.print(expr)
  res = Interpreter(EvalStencil).eval(expr, env: env)
  puts "res = #{res}\n\n\n"
  res
end

def get_env(elem)
  if elem.Group?
    res = {}
    elem.elems.each {|e| res += get_env(e)}
    res
  else
    {elem.name => (elem.value.nil? ? nil : elem.value.val)}
  end
end

require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/grammar/code/layout'
require 'core/interp-dsl/code/interp-eval.rb'
require 'core/interp-dsl/code/interp-type.rb'

myexpr = Loader.load('test.expr')
eval_expr = Loader.load('expr-eval.interp')
render_expr = Loader.load('render-expr.interp')
env = {'a' => 5}

interp = Interpreter.new(eval_expr, render_expr)
puts interp.eval(myexpr, env)
puts interp.render(myexpr)

p "Composing eval and render:"
interp.compose_varinterp('enp') do |eval, render, _fields|
  {'eval' => eval.call(Hash[*_fields.map{|k,v| [k, v['eval']]}.flatten], {'a'=>0}), 'render' => render.call}
end
p interp.enp(myexpr, env)
puts ""
interp << Loader.load('enp-expr.interp')
puts interp.enp(myexpr, env)
puts ""

p "Wrapping render with brackets:"
interp.compose_varinterp('render2') do |render, _type|
  {'render' => _type=='EBinOp' ? "(#{render.call})" : "#{render.call}" }
end
p interp.render2(myexpr)
puts ""

p "Debugging eval:"
interp.compose_varinterp('deval') do |eval, render, _type|
  ev = eval.call
  ren = render.call
  puts "Debugging #{_type}: #{ren} => #{ev}"
  {'eval' => ev, 'render' => ren}
end
p interp.deval(myexpr, env)
puts ""

require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/grammar/code/layout'
require 'core/interp-dsl/code/interp-eval.rb'
require 'core/interp-dsl/code/interp-type.rb'

test = Loader.load('test.intree')
Print.print(test)
plusone = Loader.load('plusone.interp')

interp = Interpreter.new(plusone)
interp.instance_eval {
  @fact = Factory.new(Loader.load("intree.schema"))
  def f
    puts "ooo #{@fact}"
  end
}
Print.print(interp.plusone(test))

interp.compose_varinterp('dbl') do |plusone, _fields|
  {'plusone' => plusone.call(
    Hash[*plusone.call.map{|k,v| [k, v['plusone']]}.flatten]
  )}
end

Print.print(interp.dbl(test)['plusone'])

=begin
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
=end

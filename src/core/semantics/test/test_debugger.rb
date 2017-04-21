require 'core/system/load/load'
require 'core/semantics/interpreters/debug'

#Fibo is the fibonacci function. Source found in core/expr/test/fibo.impl
# Note that the whole program is surrounded by an implicit block (EBlock)
# with two statements: the fun def and the fun call

Cache.clean('fibo.impl') #need to clean cache to get origin tracking
fib = Load::load('fibo.impl')

class DebugEvalImplC
  include Impl::EvalCommand
  include Debug::Debug
  def eval(obj)
    wrap(:eval, :debug, obj)
  end
end

interp = DebugEvalImplC.new

#run it!
exp1 = Load::load('expr1.expr')
startt=Time.now
interp.dynamic_bind(env: {'f'=>10}) do
  puts interp.eval(fib)
end
puts "debug = #{Time.now-startt}"
startt=Time.now
puts Impl::eval(fib, env: {'f'=>10})
puts "normal = #{Time.now-startt}"


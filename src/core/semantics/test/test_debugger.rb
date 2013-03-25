require 'core/system/load/load'
require 'core/semantics/interpreters/debug'

#Fibo is the fibonacci function. Source found in core/expr/test/fibo.impl
# Note that the whole program is surrounded by an implicit block (EBlock)
# with two statements: the fun def and the fun call

Cache.clean('fibo.impl') #need to clean cache to get origin tracking
fib = Load::load('fibo.impl')
FindModel::FindModel.find_model('fibo.impl') {|path| $file = IO.readlines(path)}

#EvalCommandC.new is the non-debug version
# DebugMod is parameterized by the interpreter (ie EvalCommand),

  class DebugEvalImplC
    include Impl::EvalCommand
    include Debug::Debug
    def eval(obj)
      wrap(:eval, :debug, obj)
    end
  end

interp = DebugEvalImplC.new
#interp = Impl::EvalCommandC.new

#run it!
Cache.clean('expr1.expr')
exp1 = Load::load('expr1.expr')
startt=Time.now
interp.dynamic_bind env: {'f'=>10}, stack: [], this: fib do
  puts interp.eval(fib)
end
puts "debug = #{Time.now-startt}"
startt=Time.now
puts Impl::eval(fib, env: {'f'=>10}, stack: [], this: fib)
puts "normal = #{Time.now-startt}"


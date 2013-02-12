

require 'core/semantics/factories/test/exprs'
require 'core/semantics/factories/obj-fold'
require 'core/semantics/factories/combinators'

require 'fiber'

if __FILE__ == $0 then
  ex1 = Add.new(Const.new(1), Const.new(2))
  ex2 = Add.new(Const.new(5), ex1)
  ex3 = Add.new(ex1, ex2)

  puts "### Eval"
  eval = FFold.new(Eval.new).fold(ex1)

  puts eval.eval
  
  puts "### Debug Render"
  
  eval_dbg = FFold.new(Suspend.new(:eval) < Eval.new < Render.new).fold(ex3)

  fib = Fiber.new do 
    eval_dbg.eval
  end
  i = 0
  while fib.alive? do
    event, exp, result = fib.resume
    i += 1
    if fib.alive? then
      if event == :enter
        puts (" " * i) + "Eval of #{exp.render}"
      else
        puts (" " * i) + "Result of #{exp.render} is #{result}"
        i -= 2
      end
    else
      puts "Final result: #{exp}"
    end
  end
end


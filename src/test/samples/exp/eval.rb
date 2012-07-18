
module Eval  
  operation :eval

  def eval_Num(n, args=nil)
    n
  end

  def eval_Add(left, right, args=nil)
    puts "#{left}+#{right}"
    left.eval(args) + right.eval(args)
  end

  def eval_Mul(left, right, args=nil)
    puts "#{left}*#{right}"
    left.eval(args) * right.eval(args)
  end
end


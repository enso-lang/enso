
module Eval  
  operation :eval

  def eval_Num(val)
    val
  end

  def eval_Add(left, right)
    puts "#{left}+#{right}"
    left.eval + right.eval
  end

  def eval_Mul(left, right)
    puts "#{left}*#{right}"
    left.eval * right.eval
  end
end


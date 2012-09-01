
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

  def eval_Let(val, body)
    body.eval
  end

  def eval_Var(binding)
    binding.val.eval
  end
end


require 'core/semantics/code/interpreter'

class Eval  
  include Dispatcher

  def eval(exp)
    dispatch_obj(:eval, exp)
  end

  def eval_Num(exp)
    exp.val
  end

  def eval_Add(exp)
    puts "#{exp.left}+#{exp.right}"
    eval(exp.left) + eval(exp.right)
  end

  def eval_Mul(exp)
    puts "#{exp.left}*#{exp.right}"
    eval(exp.left) * eval(exp.right)
  end

  def eval_Let(exp)
    dynamic_bind({ exp.var => eval(exp.val) }) do
      eval(exp.body)
    end
  end

  def eval_Var(exp)
    @_[exp.binding.var]
  end
end


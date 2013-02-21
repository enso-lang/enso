
require 'core/expr/code/impl'

module AssertExpr
  include Eval::EvalExpr
  include Lvalue::LValueExpr

  include Interpreter::Dispatcher  
    
  def assert(obj)
    dispatch(:assert, obj)
  end

  def assert_?(type, fields, args)
    raise "Invalid expression in grammar" unless eval
  end

  def assert_EBinOp(op, e1, e2)
    if op == "eql?"
      var = lvalue(e1)
      val = eval(e2)
      if var.nil?  #try flip it around
        var = lvalue(e2)
        val = eval(e1)
      end
      if var.nil?
        raise "Invalid expression in grammar"
      end
      var.value = val
    elsif op == "&"
      assert e1
      assert e2
    else
      raise "Invalid expression in grammar"
    end
  end

  def assert_EUnOp(op, e)
    if op == "!"
      var = lvalue(e)
      if var.nil?
        raise "Invalid expression in grammar"
      end
      var.value = false
    else
      raise "Invalid expression in grammar"
    end
  end

  def assert_EVar(name)
    var = lvalue(e)
    if var.nil?
      raise "Invalid expression in grammar"
    end
    var.value = true
  end

  def assert_EField(e, fname)
    var = lvalue(e)
    if var.nil?
      raise "Invalid expression in grammar"
    end
    var.value = true
  end
end

class AssertExprC
  include AssertExpr
  def initialize; end
end

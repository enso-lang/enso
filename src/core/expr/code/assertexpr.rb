
require 'core/expr/code/impl'

module AssertExpr
  include Eval::EvalExpr
  include Lvalue::LValueExpr

  include Interpreter::Dispatcher  

  def assert(obj)
    dispatch_obj(:assert, obj)
  end

  def assert_?(obj)
    raise "Invalid expression in grammar"
  end

  def assert_EBinOp(obj)
    if obj.op == "eql?"
      var = lvalue(obj.e1)
      val = eval(obj.e2)
      if var.nil?  #try flip it around
        var = lvalue(obj.e2)
        val = eval(obj.e1)
      end
      if var.nil?
        raise "Invalid expression in grammar"
      end
      var.value = val
    elsif obj.op == "&"
      assert obj.e1
      assert obj.e2
    else
      raise "Invalid expression in grammar"
    end
  end

  def assert_EUnOp(obj)
    if op == "!"
      var = lvalue(obj.e)
      if var.nil?
        raise "Invalid expression in grammar"
      end
      var.value = false
    else
      raise "Invalid expression in grammar"
    end
  end

  def assert_EVar(obj)
    var = lvalue(obj.e)
    if var.nil?
      raise "Invalid expression in grammar"
    end
    var.value = true
  end

  def assert_EField(obj)
    var = lvalue(obj.e)
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


require 'core/expr/code/impl'

module AssertExpr
  include EvalExpr, LValueExpr
  
  operation :assert

  def assert_?(type, fields, args)
    raise "Invalid expression in grammar" unless eval
  end

  def assert_EBinOp(op, e1, e2)
    if op == "eql?"
      var = e1.lvalue
      val = e2.eval
      if var.nil?  #try flip it around
        var = e2.lvalue
        val = e1.eval
      end
      if var.nil?
        raise "Invalid expression in grammar"
      end
      var.value = val
    elsif op == "&"
      e1.assert
      e2.assert
    else
      raise "Invalid expression in grammar"
    end
  end

  def assert_EUnOp(op, e)
    if op == "!"
      var = e.lvalue
      if var.nil?
        raise "Invalid expression in grammar"
      end
      var.value = false
    else
      raise "Invalid expression in grammar"
    end
  end

  def assert_EVar(name)
    var = e.lvalue
    if var.nil?
      raise "Invalid expression in grammar"
    end
    var.value = true
  end

  def assert_EField(e, fname)
    var = e.lvalue
    if var.nil?
      raise "Invalid expression in grammar"
    end
    var.value = true
  end
end


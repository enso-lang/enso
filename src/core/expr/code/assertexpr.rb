
require 'core/expr/code/impl'

  module AssertExpr
    include EvalExpr, LValueExpr
  
    def assert_?(type, fields, args=nil)
      return nil
      raise "Invalid expression in grammar" unless @interpreter.eval(args[:self], args)
    end
  
    def assert_EBinOp(op, e1, e2, args=nil)
      if op == "eql?"
        var = e1.lvalue(args)
        val = e2.eval(args)
        if var.nil?  #try flip it around
          var = e2.lvalue(args)
          val = e1.eval(args)
        end
        if var.nil?
          raise "Invalid expression in grammar"
        end
        var.value = val
      elsif op == "&"
        e1.assert(args)
        e2.assert(args)
      else
        raise "Invalid expression in grammar"
      end
    end
  
    def assert_EUnOp(op, e, args=nil)
      if op == "!"
        var = e.lvalue(args)
        if var.nil?
          raise "Invalid expression in grammar"
        end
        var.value = false
      else
        raise "Invalid expression in grammar"
      end
    end
  
    def assert_EVar(name, args=nil)
      var = e.lvalue(args)
      if var.nil?
        raise "Invalid expression in grammar"
      end
      var.value = true
    end
  
    def assert_EField(e, fname, args=nil)
      var = e.lvalue(args)
      if var.nil?
        raise "Invalid expression in grammar"
      end
      var.value = true
    end
  end


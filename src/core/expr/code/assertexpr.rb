
require 'core/expr/code/impl'
require 'enso'

module AssertExpr
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
        variable = lvalue(obj.e1)
        val = eval(obj.e2)
        if variable.nil?  #try flip it around
          variable = lvalue(obj.e2)
          val = eval(obj.e1)
        end
        if variable.nil?
          raise "Invalid expression in grammar"
        end
        variable.set(val)
      elsif obj.op == "&"
        assert obj.e1
        assert obj.e2
      else
        raise "Invalid expression in grammar"
      end
    end
  
    def assert_EUnOp(obj)
      if op == "!"
        variable = lvalue(obj.e)
        if variable.nil?
          raise "Invalid expression in grammar"
        end
        variable.value = false
      else
        raise "Invalid expression in grammar"
      end
    end
  
    def assert_EVar(obj)
      variable = lvalue(obj.e)
      if variable.nil?
        raise "Invalid expression in grammar"
      end
      variable.value = true
    end
  
    def assert_EField(obj)
      variable = lvalue(obj.e)
      if variable.nil?
        raise "Invalid expression in grammar"
      end
      variable.value = true
    end
  end
  
  class AssertExprC
    include AssertExpr
    def initialize; end
  end

  def self.assert(obj, args={})
    interp = AssertExprC.new
    interp.dynamic_bind(args) do
      interp.assert(obj)
    end
  end
end

require 'core/expr/code/eval'

module Construct
  
  module ConstructStencil
    include Interpreter::Dispatcher
    include Impl::EvalCommand

    def eval_Stencil
      
    end
    
  end

  module EvalExpr
    include Interpreter::Dispatcher
    include Impl::EvalCommand

    def eval_Color(r, g, b)
      factory = @D[:factory]
      factory.Color(eval(r).round, eval(g).round, eval(b).round)
    end
  
    def eval_InstanceOf(base, class_name)
      puts "checking IO for #{base} and #{class_name}"
      a = eval(base)
      a && Schema.subclass?(a.schema_class, class_name)
    end

    def eval_Eval(expr, env)
      puts "\n\n\n\@interpreter=#{@interpreter}:#{@interpreter.class}"
      Print::Print.print expr
      puts "expr.eval=#{expr.eval}"
      Print::Print.print eval(expr)
      @interpreter.eval(expr.eval, env: env)
    end

    def eval_ETernOp(op1, op2, e1, e2, e3)
      dynamic = @D[:dynamic]
      if !dynamic
        super
      else
        v = eval(e1)
        fail "NON_DYNAMIC #{v}" if !v.is_a?(Variable)
        a = eval(e2)
        b = eval(e3)
        v.test(a, b)
      end
    end
  
    def eval_EBinOp(op, e1, e2)
      dynamic = @D[:dynamic]
      if !dynamic
        super op, e1, e2
      else
        r1 = eval(e1)
        r1 = Variable.new("gen", r1) if r1 && !r1.is_a?(Variable)
        r2 = eval(e2)
        r2 = Variable.new("gen", r2) if r2 && !r2.is_a?(Variable)
        r1.send(op.to_s, r2)
      end
    end
  
    def eval_EUnOp(op, e)
      dynamic = @D[:dynamic]
      if !dynamic
        super op, e
      else
        r1 = eval(e1)
        r1 = Variable.new("gen", r1) if r1 && !r1.is_a?(Variable)
        r1.send(op.to_s)
      end
    end
  
    def eval_EField(e, fname)
      in_fc = @D[:in_fc]
      dynamic = @D[:dynamic]
    
      if in_fc or !dynamic
        super e, fname
      else
        r = eval(e)
        if r.is_a? Variable
          r = r.value.dynamic_update
        else
          r = r.dynamic_update
        end
        Print::Print.print(eval(e))
        puts @D[:env]
        r.send(fname)
      end
    end
  end
  
  class EvalExprC
    include EvalExpr
    def initialize
    end
  end

end

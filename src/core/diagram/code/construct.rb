require 'core/expr/code/eval'

module EvalStencil
  include Eval::EvalExpr

  def eval_Color(r, g, b, factory)
    factory.Color(eval(r).round, eval(g).round, eval(b).round)
  end

  def eval_InstanceOf(base, class_name)
    a = eval(base)
    a && Schema::subclass?(a.schema_class, class_name)
  end

  def eval_ETernOp(op1, op2, e1, e2, e3)
    if !@D[:dynamic]
      super
    else
      v = e1.eval
      fail "NON_DYNAMIC #{v}" if !v.is_a?(Variable)
      a = e2.eval
      b = e3.eval
      v.test(a, b)
    end
  end

  def eval_EBinOp(op, e1, e2)
    if !@D[:dynamic]
      super op, e1, e2
    else
      r1 = e1.eval
      r1 = Variable.new("gen", r1) if r1 && !r1.is_a?(Variable)
      r2 = e2.eval
      r2 = Variable.new("gen", r2) if r2 && !r2.is_a?(Variable)
      r1.send(op.to_s, r2)
    end
  end

  def eval_EUnOp(op, e)
    if !@D[:dynamic]
      super op, e
    else
      r1 = e1.eval
      r1 = Variable.new("gen", r1) if r1 && !r1.is_a?(Variable)
      r1.send(op.to_s)
    end
  end

  def eval_EField(e, fname)
    if @D[:in_fc] or !@D[:dynamic]
      super e, fname
    else
      r = eval(e)
      if r.is_a? Variable
        r = r.value.dynamic_update
      else
        r = r.dynamic_update
      end
      r.send(fname)
    end
  end

end

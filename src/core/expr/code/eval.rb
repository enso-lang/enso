require 'core/schema/code/factory'
require 'core/system/library/schema'

module EvalExpr

  include Dispatcher
  
  def eval(obj)
    dispatch(:eval, obj)
  end

  def eval_ETernOp(op1, op2, e1, e2, e3)
    eval(e1) ? eval(e2) : eval(e3)
  end

  def eval_EBinOp(op, e1, e2)
    if op == "&"
      eval(e1) && eval(e2)
    elsif op == "|"
      eval(e1) || eval(e2)
    else
      eval(e1).send(op.to_s, eval(e2))
    end
  end

  def eval_EUnOp(op, e)
    eval(e).send(op.to_s)
  end

  def eval_EVar(name)
    raise "ERROR: undefined variable #{name}" unless @_.env.has_key?(name)
    @_.env[name]
  end

  def eval_ESubscript(e, sub)
    eval(e)[eval(sub)]
  end

  def eval_EConst(val)
    val
  end

  def eval_ENil
    nil
  end

  def eval_EFunCall(fun, params)
    dynamic_bind in_fc: true do 
      eval(fun).call(*(params.map{|p|eval(p)}))
    end
  end

  def eval_EList(elems)
    k = Schema::class_key(@_.for_field.type)
    #puts "KEY #{@_.for_field}= #{k}"
    if k
      r = ManagedData::Set.new(nil, nil, k)
    else
      r = ManagedData::List.new(nil, nil)
    end
    elems.each do |elem|
      #puts "ELEM #{elem}=#{eval(elem)}"
      r << eval(elem)
    end
    r
  end

  def eval_EField(e, fname)
    if @_.in_fc
      dynamic_bind in_fc: false do
        target = eval(e)
        target.method(fname.to_sym)
      end
    else
      eval(e).send(fname)
    end
  end
end

class EvalExprC
  include EvalExpr
  def initialize
  end
end
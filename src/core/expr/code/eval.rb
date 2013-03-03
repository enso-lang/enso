require 'core/schema/code/factory'
require 'core/system/library/schema'
require 'core/semantics/code/interpreter'

module Eval  
  module EvalExpr
  
    include Interpreter::Dispatcher

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
      raise "ERROR: undefined variable #{name} in #{@D[:env]}" unless @D[:env].has_key?(name)
      @D[:env][name]
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
      m = dynamic_bind in_fc: true do 
        eval(fun)
      end
      m.call_closure(*(params.map{|p|eval(p)}))
    end
  
    def eval_EList(elems)
      elems.map do |elem|
        #puts "ELEM #{elem}=#{eval(elem)}"
        eval(elem)
      end
    end
  
    #reason for in_fc is to disambiguate between the following 2 cases:
    #  a.foo   -- (EField (Var 'a') (Str 'foo'))
    #  a.foo() -- (EFunCall (EField (Var 'a') (Str 'foo')))
    #In the former, EField should return the result of calling foo on a,
    # in most cases, this is an accessor to get the value of field @foo
    #In the latter, EField should return the method corresponding to foo
    # itself to be called in the enclosing FunCall
    #This distinction is particular to Ruby, since it wraps the first
    # case as an implicit function call. In Javascript, the first case
    # will (correctly) return the accessor method without calling it.
    def eval_EField(e, fname)
      target = dynamic_bind in_fc: false do
        eval(e)
      end
      if @D[:in_fc]
        target.method(fname.to_sym)
      else
        target.send(fname)
      end
    end
  end
  
  class EvalExprC
    include EvalExpr
    def initialize
    end
  end

  def self.eval(obj, *args)
    interp = EvalExprC.new
    if args.empty?
      interp.eval(obj)
    else
      interp.dynamic_bind *args do
        interp.eval(obj)
      end
    end
  end

  def self.make_const(factory, val)
    if val.is_a?(String)
      factory.EStrConst(val)
    elsif val.is_a?(Integer)
      factory.EIntConst(val)
    elsif val.is_a?(TrueClass) or val.is_a?(FalseClass)
      factory.EBoolConst(val)
    elsif val.nil?
      factory.ENil
    elsif val.is_a? Factory::MObject
      val
    else
      raise "Trying to make constant using an invalid #{val.class} object" 
    end
  end

end
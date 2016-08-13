require 'core/system/library/schema'
require 'core/semantics/code/interpreter'

module Eval  
  module EvalExpr
    include Interpreter::Dispatcher

    def eval(obj)
      dispatch_obj(:eval, obj)
    end
  
    def eval_ETernOp(obj)
      eval(obj.e1) ? eval(obj.e2) : eval(obj.e3)
    end

    def eval_EBinOp(obj)
      if obj.op == "&"
        eval(obj.e1) && eval(obj.e2)
      elsif obj.op == "|"
        eval(obj.e1) || eval(obj.e2)
      elsif obj.op == "eql?"
        eval(obj.e1) == eval(obj.e2)
      elsif obj.op == "!="
        eval(obj.e1) != eval(obj.e2)
      elsif obj.op == "+"
        eval(obj.e1) + eval(obj.e2)
      elsif obj.op == "*"
        eval(obj.e1) * eval(obj.e2)
      elsif obj.op == "-"
        eval(obj.e1) - eval(obj.e2)
      elsif obj.op == "/"
        eval(obj.e1) / eval(obj.e2)
      elsif obj.op == "<"
        eval(obj.e1) < eval(obj.e2)
      elsif obj.op == ">"
        eval(obj.e1) > eval(obj.e2)
      elsif obj.op == "<=" 
        eval(obj.e1) <= eval(obj.e2)
      elsif obj.op == ">=" 
        eval(obj.e1) >= eval(obj.e2)
      else
        raise "Unknown operator (#{obj.op.to_s})"
      end
    end
  
    def eval_EUnOp(obj)
      if obj.op == "!"
        !eval(obj.e)
      else
        raise "Unknown operator (#{obj.op})"
      end
    end

    def eval_EVar(obj)
      env = @D[:env]
      raise "ERROR: environment not defined" unless env
      raise "ERROR: undefined variable #{obj.name} in #{env}" unless env.has_key?(obj.name.to_s)
      env[obj.name.to_s]
    end
  
    def eval_ESubscript(obj)
      eval(obj.e)[eval(obj.sub)]
    end
  
    def eval_EConst(obj)
      obj.val
    end
  
    def eval_ENil(obj)
      nil
    end
  
    def eval_EFunCall(obj)
      m = dynamic_bind(in_fc: true) do 
        eval(obj.fun)
      end
      m.call_closure(*(obj.params.map{|p|eval(p)}))
    end
  
    def eval_EList(obj)
      obj.elems.map do |elem|
        #puts "ELEM #{elem}=#{eval(elem)}"
        eval(elem)
      end
    end
  
    def eval_InstanceOf(obj)
      a = eval(obj.base)
      a && Schema::subclass?(a.schema_class, obj.class_name)
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
    def eval_EField(obj)
      target = dynamic_bind(in_fc: false) do
        eval(obj.e)
      end
      if @D[:in_fc]
        target.method(obj.fname.to_sym)
      elsif target.respond_to?(obj.fname)
        r = target.send(obj.fname)
        #puts "EFIELD #{target}.#{obj.fname} => #{r}"
        r
      elsif target.is_a?(Enumerable)
        r = target.collect do |t|
          t.send(obj.fname)
        end
        #puts "EFIELD* #{target}.#{obj.fname} => #{r}"
        r
      end
    end
  end

  def self.make_const(factory, val)
    if val.is_a?(String)
      factory.EStrConst(val)
    elsif val.is_a?(Integer) and val%1==0 #remainder test is needed for JS conversion [JS HACK]
      factory.EIntConst(val)
    elsif val.is_a?(Float) and val%1!=0
      factory.ERealConst(val)
    elsif val.is_a?(TrueClass) or val.is_a?(FalseClass)
      factory.EBoolConst(val)
    elsif val.nil?
      factory.ENil
    else
      val
    end
  end

  def self.make_default_const(factory, type)
    case type
    when 'int'
      factory.EIntConst
    when 'str'
      factory.EStrConst
    when 'bool'
      factory.EBoolConst
    when 'real'
      factory.ERealConst
    end
  end  

  class EvalExprC
    include EvalExpr
    def initialize; end
  end

  def self.eval(obj, args={env:{}})
    interp = EvalExprC.new
    interp.dynamic_bind(args) do
      interp.eval(obj)
    end
  end

end

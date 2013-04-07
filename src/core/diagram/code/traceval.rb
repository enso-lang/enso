require 'core/schema/code/factory'
require 'core/semantics/code/interpreter'
require 'core/expr/code/env'
require 'core/expr/code/impl'
require 'core/expr/code/eval'
require 'core/schema/tools/union'

module Traceval
  module TracevalCommand
    include Interpreter::Dispatcher
    include Impl::EvalCommand

    def eval_EBinOp(obj)
      res = nil
      case obj.op
      when "&"
        res = eval(obj.e1) && eval(obj.e2)
      when "|"
        res = eval(obj.e1) || eval(obj.e2)
      when "eql?"
        res = eval(obj.e1) == eval(obj.e2)
      when "+"
        res = eval(obj.e1) + eval(obj.e2)
      when "*"
        res = eval(obj.e1) * eval(obj.e2)
      when "-"
        res = eval(obj.e1) - eval(obj.e2)
      when "/"
        res = eval(obj.e1) / eval(obj.e2)
      when "<"
        res = eval(obj.e1) < eval(obj.e2)
      when ">"
        res = eval(obj.e1) > eval(obj.e2)
      when "<=" 
        res = eval(obj.e1) <= eval(obj.e2)
      when ">=" 
        res = eval(obj.e1) >= eval(obj.e2)
      else
        raise "Unknown operator (#{obj.op})"
      end
      src = @D[:factory][obj.schema_class.name]
      src.op = obj.op
      src.e1 = @D[:src][obj.e1]
      src.e2 = @D[:src][obj.e2]
      @D[:src][obj] = src
      res
    end

    def eval_EUnOp(obj)
      res = if obj.op == "!"
        !eval(obj.e)
      else
        raise "Unknown operator (#{obj.op})"
      end
      src = @D[:factory][obj.schema_class.name]
      src.op = obj.op
      src.e = @D[:src][obj.e]
      @D[:src][obj] = src
      res
    end
  
    def eval_EVar(obj)
      raise "ERROR: undefined variable #{obj.name} in #{@D[:env]}" unless @D[:env].has_key?(obj.name)
      res = @D[:env][obj.name]
      if !res.is_a? Factory::MObject #if this result is a constant then just list it as a constant
        if @D[:srctemp][obj.name]
          @D[:src][obj] = @D[:srctemp][obj.name]
        else
          @D[:src][obj] = Eval::make_const(@D[:factory], res)
        end
      else #if it came from somewhere then remember that place as a path, ie EField
        path = Union::Copy(@D[:factory], res._path.path)
        @D[:src][obj] = path
      end
      res
    end

    def eval_EConst(obj)
      res = obj.val
      @D[:src][obj] = Eval::make_const(@D[:factory], res)
      res
    end

    def eval_ENil(obj)
      @D[:src][obj] = @D[:factory].ENil
      nil
    end

    def eval_EField(obj)
      target = dynamic_bind in_fc: false do
        eval(obj.e)
      end
      res = if @D[:in_fc]
        target.method(obj.fname.to_sym)
      else
        target.send(obj.fname)
      end
      src = @D[:factory][obj.schema_class.name]
      src.fname = obj.fname
      src.e = @D[:src][obj.e]
      @D[:src][obj] = src
      res
    end

    def eval_EFunCall(obj)
      m = dynamic_bind in_fc: true do
        eval(obj.fun)
      end
      params = obj.params.map{|p|eval(p)}
      if obj.fun.EVar? and @D[:srctemp][obj.fun.name]!=nil
        clos = @D[:srctemp][obj.fun.name]
        newsrctmp = @D[:srctemp].clone
        clos.formals.each_with_index do |f,i|
          param_src = @D[:src][obj.params[i]]
          newsrctmp[f] = param_src
        end
        res = nil
        if obj.lambda.nil?
          dynamic_bind srctemp: newsrctmp do
            res = m.call(*params)
          end
        else
          b = eval(obj.lambda)
          dynamic_bind srctemp: newsrctmp do
            res = m.call(*params, &b)
          end
        end
        @D[:src][obj] = @D[:src][clos.body]
        res
      else
        if obj.lambda.nil?
          res = m.call(*params)
        else
          b = eval(obj.lambda)
          res = m.call(*params, &b)
        end
        @D[:src][obj] = Eval::make_const(@D[:factory], res)
        res
      end
    end
    
    def eval_EBlock(obj)
      res = nil
      #fundefs are able to see each other but not any other variable created in the block
      defenv = Env::HashEnv.new({}, @D[:env])
      dynamic_bind in_fc: false, env: defenv do
        obj.fundefs.each do |c|
          eval(c)
        end
      end
      #rest of body can see fundefs
      env1 = Env::HashEnv.new({}, defenv)
      dynamic_bind in_fc: false, env: env1 do
        obj.body.each do |c|
          res = eval(c)
        end
      end
      last = obj.body[obj.body.size-1]
      @D[:src][obj] = @D[:src][last]
      res
    end

    def eval_EWhile(obj)
      res = while eval(obj.cond)
        eval(obj.body)
      end
      @D[:src][obj] = @D[:src][obj.body]
      res
    end

    def eval_EFor(obj)
      nenv = Env::HashEnv.new({obj.var=>nil}, @D[:env])
      res = eval(obj.list).each do |val|
        nenv[obj.var] = val
        dynamic_bind env: nenv do
          eval(obj.body)
        end
      end
      @D[:src][obj] = @D[:src][obj.body]
      res
    end

    def eval_EIf(obj)
      if eval(obj.cond)
        res = eval(obj.body)
        @D[:src][obj] = @D[:src][obj.body]
        res
      elsif !obj.body2.nil?
        res = eval(obj.body2)
        @D[:src][obj] = @D[:src][obj.body2]
        res
      end
    end

    def eval_EFunDef(obj)
      forms = []
      obj.formals.each {|f| forms << f.name}
      @D[:env][obj.name] = Impl::Closure.make_closure(obj.body, forms, @D[:env], self)
      @D[:srctemp][obj.name] = Impl::Closure.new(obj.body, forms, @D[:env], self)
      nil
    end

    def eval_EAssign(obj)
      lvalue(obj.var).value = eval(obj.val)
      if (obj.var.EVar?)
        @D[:srctemp][obj.var.name] = @D[:src][obj.val]
      end
    end
  end

  class TracevalCommandC
    include TracevalCommand
    def initialize; end
  end

  def self.eval(obj, args={})
    interp = TracevalCommandC.new
    interp.dynamic_bind args do
      interp.eval(obj)
    end
  end

end

require 'core/semantics/code/interpreter'
require 'core/expr/code/impl'

module Traceval
  module TracevalCommand
    include Interpreter::Dispatcher
    include Impl::EvalCommand

    def eval_EBinOp(obj)
      res = super(obj)
      src = @D[:factory][obj.schema_class.name]
      src.op = obj.op
      src.e1 = @D[:src][obj.e1]
      src.e2 = @D[:src][obj.e2]
      @D[:src][obj] = src
      res
    end

    def eval_EUnOp(obj)
      res = super(obj)
      src = @D[:factory][obj.schema_class.name]
      src.op = obj.op
      src.e = @D[:src][obj.e]
      @D[:src][obj] = src
      res
    end
  
    def eval_EVar(obj)
      res = super(obj)
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
      res = super(obj)
      @D[:src][obj] = Eval::make_const(@D[:factory], res)
      res
    end

    def eval_EField(obj)
      res = super(obj)
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
      res = super(obj)
      last = obj.body[obj.body.size-1]
      @D[:src][obj] = @D[:src][last]
      res
    end

    def eval_EWhile(obj)
      res = super(obj)
      @D[:src][obj] = @D[:src][obj.body]
      res
    end

    def eval_EFor(obj)
      res = super(obj)
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
      super(obj)
      forms = []
      obj.formals.each {|f| forms << f.name}
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
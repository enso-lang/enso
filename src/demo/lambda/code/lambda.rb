require 'core/system/load/load'
require 'core/expr/code/env'

module Lambda

  # simple lambda calc evaluator
  # currently does not consider var capturing

  module EvalLambda
    include Interpreter::Dispatcher

    def eval(obj)
      dispatch_obj(:eval, obj)
    end

    def init
      super
      @D._bind(:env, HashEnv.new)
    end

    def eval_App(obj)
      fun = eval(obj.fun)
      arg = eval(obj.arg)
      if fun and arg and fun.is_a?("Lambda")
      end
    end

    def eval_Lambda(obj)
      obj
    end

    def eval_Var(obj)
      @D[:env][obj.name]
    end

    def subst(obj)
      dispatch_obj(:subst, obj)
    end

    def subst_App(obj)
      obj.fun = subst(obj.fun)
      obj.arg = subst(obj.arg)
      obj
    end

    def subst_Var(obj)
      @D[:from] == obj.name ? @D[:to] : obj
    end

    def subst_Lambda(obj)
      if @D[:from] == obj.var
        obj
      else
        obj.body = subst(obj.body)
      end
      obj
    end

    def freeVar(obj)
      dispatch_obj(:freeVar, obj)
    end

    def freeVar_App(obj)
      freeVar(obj.fun) + freeVar(obj.arg)
    end

    def freeVar_Var(obj)
      @D[:bound].include?(obj.name) ? [] : [obj.name]
    end

    def freeVar_Lambda(obj)
      @D[:bound] << obj.var
      freeVar(obj.body)
    end
  end

  class EvalLambdaC
    include EvalLambda
  end
end





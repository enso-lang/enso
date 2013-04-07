require 'core/expr/code/impl'
require 'core/expr/code/env'
require 'core/expr/code/env'
require 'core/diagram/code/traceval'
require 'core/schema/code/factory'

module Evalexprstencil

  module EvalExprStencil
    include Traceval::TracevalCommand
#    include Impl::EvalCommand

    def eval_Rule(obj)
      funname = "#{obj.name}__#{obj.type}"
      #create a new function
      forms = [obj.obj]
      obj.formals.each {|f| forms << f.name}
      @D[:env][funname] = Impl::Closure.make_closure(obj.body, forms, @D[:env], self)
      @D[:srctemp][funname] = Impl::Closure.new(obj.body, forms, @D[:env], self)
    end

    def eval_RuleCall(obj)
      target = eval(obj.obj)
      funname = "#{obj.name}__#{target.schema_class.name}"
      m = @D[:env][funname]
      params = obj.params.map{|p|eval(p)}

      clos = @D[:srctemp][funname]
      newsrctmp = @D[:srctemp].clone
      clos.formals.each_with_index do |f,i|
        if (i==0)
          newsrctmp[f] = target
        else
          param_src = @D[:src][obj.params[i-1]]
          newsrctmp[f] = param_src
        end
      end
      res = nil
      dynamic_bind srctemp: newsrctmp do
        res = m.call(target, *params)
      end
      @D[:src][obj] = @D[:src][clos.body]
      res
    end

    def eval_EFor(obj)
      nenv = Env::HashEnv.new({obj.var=>nil}, @D[:env])
      res = eval(obj.list).map do |val|  #returns list of results instead of only last result
        nenv[obj.var] = val
        dynamic_bind env: nenv do
          eval(obj.body)
        end
      end
      @D[:src][obj] = @D[:src][obj.body]
      res
    end
  
    def eval_InstanceOf(obj)
      a = eval(obj.base)
      a && Schema::subclass?(a.schema_class, obj.class_name)
    end

    def eval_Eval(obj)
      env1 = Env::HashEnv.new
      obj.envs.map{|e| eval(e)}.each do |env|
        if env.is_a? Factory::List
          env.each do |v|
            env1[v.name] = v
          end
        else
          env.each_pair do |k,v|
            env1[k] = v
          end
        end
      end
      expr1 = eval(obj.expr)
      res = dynamic_bind env: env1 do
        eval(expr1)
      end
      puts "src for inner=#{@D[:src][expr1]}"
      @D[:src][obj] = @D[:src][expr1]
      res
    end

  end    
end

require 'core/expr/code/eval'
require 'core/expr/code/lvalue'
require 'core/semantics/code/interpreter'
require 'core/expr/code/env'

module Impl
  #note that the closure stores variable states only,
  #not interpreter state
  #so calling a closure may produce different behavior
  #depending on where it is evaluated because the
  #interpreter may be different
  class Closure
    attr_reader :formals, :body

    def self.make_closure(body, formals, env, interp)
      Closure.new(body, formals, env, interp).method('call_closure')
    end

    def initialize(body, formals, env, interp)
      @body = body
      @formals = formals
      @env = env
      @interp = interp
    end

    #params are the values used to call this function
    #args are used by the interpreter
    def call_closure(*params)
      #puts "CALL #{@formals} #{params}"
      nv = {}
      @formals.each_with_index do |f,i|
        nv[f] = params[i]
      end
      nenv = Env::HashEnv.new(nv, @env)
      @interp.dynamic_bind(env: nenv) do
        @interp.eval(@body)
      end
    end

    def to_s()
      "#<Closure(#{@formals.map{|f|f.name}.join(", ")}) {#{@body}}>"
    end
  end

  module EvalCommand
  
    include Eval::EvalExpr
    include Lvalue::LValueExpr
    
    include Interpreter::Dispatcher    
      
    def eval(obj)
      dispatch_obj(:eval, obj)
    end
    
    def eval_EWhile(obj)
      while eval(obj.cond)
        eval(obj.body)
      end
    end

    def eval_EFor(obj)
      env = {}
      env[obj.var] = nil
      nenv = Env::HashEnv.new(env, @D[:env])
      eval(obj.list).each do |val|
        nenv[obj.var] = val
        dynamic_bind(env: nenv) do
          eval(obj.body)
        end
      end
    end
  
    def eval_EIf(obj)
      if eval(obj.cond)
        eval(obj.body)
      elsif !obj.body2.nil?
        eval(obj.body2)
      end
    end

    def eval_EBlock(obj)
      res = nil
      #fundefs are able to see each other but not any other variable created in the block
      defenv = Env::HashEnv.new({}, @D[:env])
      dynamic_bind(in_fc: false, env: defenv) do
        obj.fundefs.each do |c|
          eval(c)
        end
      end
      #rest of body can see fundefs
      env1 = Env::HashEnv.new({}, defenv)
      dynamic_bind(in_fc: false, env: env1) do
        obj.body.each do |c|
          res = eval(c)
        end
      end
      res
    end

    def eval_EFunDef(obj)
      forms = []
      obj.formals.each {|f| forms << f.name}
      @D[:env][obj.name] = Impl::Closure.make_closure(obj.body, forms, @D[:env], self)
      nil
    end

    def eval_ELambda(obj)
      forms = []
      obj.formals.each {|f| forms << f.name}
      Proc.new { |*p| Impl::Closure.make_closure(obj.body, forms, @D[:env], self).call(*p) }
    end

    def eval_EFunCall(obj)
      m = dynamic_bind(in_fc: true) do
        eval(obj.fun)
      end
      if obj.lambda.nil?
        
        m.call(*(obj.params.map{|p|eval(p)}))
      else
        b = eval(obj.lambda)
        m.call(*(obj.params.map{|p|eval(p)}), &b) 
      end
    end

    def eval_EAssign(obj)
      lvalue(obj.var).value = eval(obj.val)
    end
  end
  
  class EvalCommandC
    include EvalCommand
    def initialize
    end
  end
        
  def self.eval(obj, args = {env:{}})

  	local_funs = {}
  	local_funs["MAX"] = Proc.new { |*a|
	  	  max = nil
	  	  #puts "MAX #{a}"
	  	  a.each do |b|
		  	  if b.is_a?(Enumerable)
		  	    b.each do |v|
		  	      max = max.nil? ? v : [max, v].max
		  	    end
		  	  else
		  	    max = max.nil? ? b : [max, b].max
		  	  end
		  	end
		  	max
	    }
  	local_funs["MIN"] = Proc.new { |*a|
	  	  min = nil
	  	  #puts "MIN #{a}"
	  	  a.each do |b|
		  	  if b.is_a?(Enumerable)
		  	    b.each do |v|
		  	      min = min.nil? ? v : [min, v].min
		  	    end
		  	  else
		  	    min = min.nil? ? b : [min, b].min
		  	  end
		  	end
		  	min
      }
  	local_funs["SUM"] = Proc.new { |*a|
        sum = 0
	  	  a.each do |b|
	  	    if b.is_a?(Enumerable)
		  	    b.each do |v|
		  	      sum = sum + v
		  	    end
		  	  else
		  	    sum = sum + b
		  	  end
		  	end
		  	sum
	    }
  	local_funs["COUNT"] = Proc.new { |*a|
	  	  count = nil
	  	  a.each do |b|
		  	  if b.is_a?(Enumerable)
		  	    b.each do |v|
		  	      count = count.nil? ? 1 : count + 1
		  	    end
		  	  else
		  	    count = count.nil? ? 1 : count + 1
		  	  end
		  	end
		  	count
	    }
  	local_funs["AVERAGE"] = Proc.new { |*a|
	  	  local_funs["SUM"].call(*a) / local_funs["COUNT"].call(*a)
	    }
  	local_funs["STDEV"] = Proc.new { |*a|
	  	  average = local_funs["AVERAGE"].call(*a)
	  	  sumvariance = 0
	  	  count = 0
	  	  a.each do |b|
		  	  if b.is_a?(Enumerable)
		  	    b.each do |v|
		  	      p = v - average
		  	      sumvariance = sumvariance + (p * p) 
		  	      count = count + 1
		  	    end
		  	  else
	  	      p = b - average
	  	      sumvariance = sumvariance + (p * p)
    	      count = count + 1
		  	  end
		  	end
		  	Math.sqrt(sumvariance / count)
	    }
  	local_funs["MEDIAN"] = Proc.new { |*a|
	  	  arr = []
	  	  a.each do |b|
		  	  if b.is_a?(Enumerable)
		  	    b.each do |v|
		  	      arr << v
		  	    end
		  	  else
		  	    arr << b
		  	  end
		  	end
			  mid = arr.length / 2
			  sorted = arr.sort
			  #puts "MID #{mid} #{sorted}"
			  mid.odd? ? sorted[mid] : 0.5 * (sorted[mid] + sorted[mid - 1])
	    }
    
  
    nv = Env::HashEnv.new(local_funs, args[:env])
    args[:env] = nv
    interp = EvalCommandC.new
    interp.dynamic_bind(args) do
      interp.eval(obj)
    end
  end
end

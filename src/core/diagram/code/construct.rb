require 'core/expr/code/eval'
require 'core/expr/code/renderexp'
require 'core/semantics/code/interpreter'
require 'core/expr/code/impl'
require 'core/expr/code/env'
require 'core/schema/code/factory'
require 'core/system/load/load'
require 'core/system/library/schema'
require 'core/schema/tools/union'

module Construct

  module EvalStencil
    include Impl::EvalCommand

    def eval_Stencil(obj)
      factory = Factory::SchemaFactory.new(Load::load('diagram.schema'))
      res = factory.Stencil(obj.title, obj.root)
      env = {}
      env["data"] = @D[:data]
      dynamic_bind env: env, 
      			   factory: factory,
      			   props: {} do
        res.body = eval(obj.body)
      end
      res
    end

    def handle_props(props)
      nprops = @D[:props].clone
      props.each do |p|
        p1 = eval(p)
        name = p1.var
        nprops[p1.var] = p1
      end
      nprops
    end

    def eval_?(obj)
      # simple copy that evaluates the "holes"
      type = obj.schema_class
      factory = @D[:factory]
      res = factory[type.name]
      nprops = handle_props(obj.props)
      nprops.values.each {|p| res.props << p }        
      type.fields.each do |f|
        if !(f.name=="label" or f.name=="props")
          if f.type.Primitive?
            res[f.name] = obj[f.name]
          elsif f.type.name=="Expr"
            if obj[f.name].nil?
              res[f.name] = nil
            else
              res[f.name] = Eval::make_const(factory, eval(obj[f.name]))
            end
          else
            if !f.many
    	        dynamic_bind props: nprops do
                res[f.name] = eval(obj[f.name])
  	        end
            else
              obj[f.name].each do |item|
                dynamic_bind props: nprops do
                  ev = eval(item)
                  if ev.is_a? Array    # flatten arrays
                    ev.each {|e| if not e.nil?; res[f.name] << e; end}
                  elsif not ev.nil?
                    res[f.name] << ev
                  end 
                end
              end
            end
          end
        end
      end
      unless obj.label.nil?
        @D[:env][obj.label] = res
      end
      res
    end

    def eval_Prop(obj)
      factory = @D[:factory]
      res = factory.Prop
      res.var = obj.var
      res.val = Eval::make_const(factory, eval(obj.val))
      res
    end

    def eval_Rule(obj)
      funname = "#{obj.name}__#{obj.type}"
      #create a new function
      forms = [obj.obj]
      obj.formals.each {|f| forms << f.name}
      @D[:env][funname] = Impl::Closure.make_closure(obj.body, forms, @D[:env], self)
    end

    def eval_RuleCall(obj)
      target = eval(obj.obj)
      funname = "#{obj.name}__#{target.schema_class.name}"
      args = obj.params.map{|p|eval(p)}
      @D[:env][funname].call(target, *args)
    end

    def eval_EFor(obj)
      nenv = Env::HashEnv.new({obj.var=>nil}, @D[:env])
      eval(obj.list).map do |val|  #returns list of results instead of only last result
        nenv[obj.var] = val
        dynamic_bind env: nenv do
          eval(obj.body)
        end
      end
    end

    def eval_Pages(obj)
      factory = @D[:factory]
      res = factory.Pages
      nprops = handle_props(obj.props)
      nprops.values.each {|p| res.props << p }
      obj.items.each do |item|
        dynamic_bind props: nprops do
          ev = eval(item)
          if ev.is_a? Array    # flatten arrays
            ev.flatten.each {|e| if not e.nil?; res.items << e; end}
          elsif not ev.nil?
            res.items << ev
          end
        end
      end
      #####FIXME: Ugly hack to make Eval work
      if obj.current.Eval?
        neval = factory.Eval
        res.current = neval
      else
        res.current = Union::Copy(factory, obj.current)
      end
      unless obj.label.nil?
        @D[:env][obj.label] = res
      end
      res
    end

    def eval_Color(obj)
      factory = @D[:factory]
      r1 = Eval::make_const(factory, Math.round(eval(obj.r)))
      g1 = Eval::make_const(factory, Math.round(eval(obj.g)))
      b1 = Eval::make_const(factory, Math.round(eval(obj.b)))
      factory.Color(r1,g1,b1)
    end
  
    def eval_InstanceOf(obj)
      a = eval(obj.base)
      a && Schema::subclass?(a.schema_class, obj.class_name)
    end

    def eval_Eval(obj)
      env1 = Env::HashEnv.new
      obj.envs.map{|e| eval(e)}.each do |env|
        env.each_pair do |k,v|
          env1[k] = v
        end
      end
      expr1 = eval(obj.expr)
      Eval::eval(expr1, env: env1)
    end
  end
  
  class EvalStencilC
    include EvalStencil
    def initialize
    end
  end

  def self.eval(obj, args={})
    interp = EvalStencilC.new
    interp.dynamic_bind args do
      interp.eval(obj)
    end
  end

end

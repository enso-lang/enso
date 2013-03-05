require 'core/expr/code/eval'
require 'core/expr/code/render'

module Construct

  module EvalStencil
    include Interpreter::Dispatcher
    include Impl::EvalCommand

    def eval_Stencil(title, root, body)
      factory = Factory::SchemaFactory.new(Load::load('diagram.schema'))
      res = factory.Stencil(title, root)
      dynamic_bind env: {"data"=>@D[:data]}, 
      			   factory: factory,
      			   props: {} do
        res.body = eval(body)
      end
      res
    end

    def handle_props(props)
      nprops = @D[:props].clone
      props.each do |p|
        p1 = eval(p)
		nprops[Render::render(p1.var)] = p1
      end
      nprops
    end

    def eval_?(type, obj, args)
      # simple copy that evaluates the "holes"
      factory = @D[:factory]
      res = factory[type.name]
      nprops = handle_props(obj.props)
      nprops.values.each {|p| res.props << p }        
      type.fields.each do |f|
        next if f.name=="label" or f.name=="props"
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
                  ev.flatten.each {|e| if not e.nil?; res.items << e; end}
                elsif not ev.nil?
                  res.items << ev
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

    def eval_Prop(var, val)
      factory = @D[:factory]
      res = factory.Prop
      res.var = factory.EStrConst(Render::RenderExprC.new.render(var))
      res.val = Eval::make_const(factory, eval(val))
      res
    end

    def eval_EFor(var, list, body)
      nenv = Env::HashEnv.new.set_parent(@D[:env])
      eval(list).map do |val|  #returns list of results instead of only last result
        nenv[var] = val
        dynamic_bind env: nenv do
          eval(body)
        end
      end
    end
    
  end

  module EvalExpr
    include Interpreter::Dispatcher
    include Eval::EvalExpr

    def eval_Color(r, g, b)
      factory = @D[:factory]
      r1 = Eval::make_const(factory, eval(r).round)
      g1 = Eval::make_const(factory, eval(g).round)
      b1 = Eval::make_const(factory, eval(b).round)
      factory.Color(r1,g1,b1)
    end
  
    def eval_InstanceOf(base, class_name)
      a = eval(base)
      a && Schema.subclass?(a.schema_class, class_name)
    end

    def eval_Eval(expr, envs)
      env1 = Env::HashEnv.new
      envs.map{|e| eval(e)}.each do |env|
        env.each_pair do |k,v|
          env1[k] = v
        end
      end
      expr1 = eval(expr)
      Eval::eval(expr1, env: env1)
    end

    def eval_ETernOp(op1, op2, e1, e2, e3)
      dynamic = @D[:dynamic]
      if !dynamic
        super
      else
        v = eval(e1)
        fail "NON_DYNAMIC #{v}" if !v.is_a?(Variable)
        a = eval(e2)
        b = eval(e3)
        v.test(a, b)
      end
    end
  
    def eval_EBinOp(op, e1, e2)
      dynamic = @D[:dynamic]
      if !dynamic
        super op, e1, e2
      else
        r1 = eval(e1)
        r1 = Variable.new("gen", r1) if r1 && !r1.is_a?(Variable)
        r2 = eval(e2)
        r2 = Variable.new("gen", r2) if r2 && !r2.is_a?(Variable)
        r1.send(op.to_s, r2)
      end
    end
  
    def eval_EUnOp(op, e)
      dynamic = @D[:dynamic]
      if !dynamic
        super op, e
      else
        r1 = eval(e1)
        r1 = Variable.new("gen", r1) if r1 && !r1.is_a?(Variable)
        r1.send(op.to_s)
      end
    end
  
    def eval_EField(e, fname)
      in_fc = @D[:in_fc]
      dynamic = @D[:dynamic]
    
      if in_fc or !dynamic
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
  
  class EvalStencilC
    include EvalExpr
    include EvalStencil
    def initialize
    end
  end

  def self.eval(obj, *args)
    interp = EvalStencilC.new
    if args.empty?
      interp.eval(obj)
    else
      interp.dynamic_bind *args do
        interp.eval(obj)
      end
    end
  end

end

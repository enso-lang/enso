require 'core/expr/code/eval'
require 'core/expr/code/lvalue'
require 'core/expr/code/renderexp'
require 'core/semantics/code/interpreter'
require 'core/expr/code/impl'
require 'core/expr/code/env'
require 'core/schema/code/factory'
require 'core/system/load/load'
require 'core/system/library/schema'
require 'core/schema/tools/union'
require 'core/diagram/code/evalexprstencil'

module Construct

  module EvalStencil
    include Interpreter::Dispatcher
    include Evalexprstencil::EvalExprStencil

    def eval_Stencil(obj)
      factory = Factory::SchemaFactory.new(Load::load('diagram.schema'))
      res = factory.Stencil(obj.title, obj.root)
      env = {}
      env["data"] = @D[:data]
      src = {}
      dynamic_bind env: env, 
      			   factory: factory,
      			   src: src,
      			   srctemp: {},
      			   props: {} do
        res.body = eval(obj.body)
      end
      res
    end

    def flatten(arr)
      if arr.is_a? Array
        res = []
        arr.each {|a|res = res.concat(flatten(a))}
        res
      else
        if arr.nil?
          []
        else
          [arr]
        end
      end
    end

    def eval_?(obj)
      # simple copy that evaluates the "holes"
      type = obj.schema_class
      factory = @D[:factory]
      res = factory[type.name]
      type.fields.each do |f|
        if f.type.name=="Expr" # and res.schema_class.fields[f.name].type.name!="Expr"
          if obj[f.name].nil?
            res[f.name] = nil
          elsif !f.many
            res[f.name] = Eval::make_const(factory, eval(obj[f.name]))
            addr = @D[:src][obj[f.name]]
            if !addr.nil?

              env = {}
              env['root'] = @D[:data]
              val = Eval::eval(addr, env: env)
              raise "val=#{val}, res=#{res[f.name].val}" unless res[f.name].val==val  

              @D[:modelmap][res[f.name].to_s] = addr 
            end
          else
            obj[f.name].each do |item|
              ev = eval(item)
              if ev.is_a? Array    # flatten arrays
                ev.each {|e| if not e.nil?; res[f.name] << factory.Label(Eval::make_const(factory, e)); end}
              elsif not ev.nil?
                res[f.name] << factory.Label(Eval::make_const(factory, ev))
              end 
            end
          end
        else
          if f.type.Primitive?
            res[f.name] = obj[f.name]
          elsif !f.many
            res[f.name] = eval(obj[f.name])
          else
            obj[f.name].each do |item|
              ev = eval(item)
              flatten(ev).each {|e| res[f.name] << e}
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

    def eval_SelectMulti(obj)
      type = obj.schema_class
      factory = @D[:factory]
      res = factory[type.name]
      res.label = obj.label
      obj.props.each do |prop|
        res.props << factory.Prop(prop.var, Eval::make_const(factory, eval(prop.val)))
      end
      res.value = Eval::make_const(factory, eval(obj.value))
#      obj.choices.map{|c|eval(c)}.each do |choice|
      obj.choices.each do |choice|
        cs = eval(choice)
        cs.each do |c|
          res.choices << Eval::make_const(factory, c)
        end
      end
      res
    end

    def eval_SelectSingle(obj)
      type = obj.schema_class
      factory = @D[:factory]
      res = factory[type.name]
      res.label = obj.label
      obj.props.each do |prop|
        res.props << factory.Prop(prop.var, Eval::make_const(factory, eval(prop.val)))
      end
      res.value = Eval::make_const(factory, eval(obj.value))
      obj.choices.each do |choice|
        cs = eval(choice)
        cs.each do |c|
          res.choices << Eval::make_const(factory, c)
        end
      end
      res
    end

    def eval_Pages(obj)
      factory = @D[:factory]
      res = factory.Pages
      res.label = obj.label
      obj.props.each do |prop|
        res.props << factory.Prop(prop.var, Eval::make_const(factory, eval(prop.val)))
      end
      obj.items.each do |item|
          ev = eval(item)
          if ev.is_a? Array    # flatten arrays
            ev.flatten.each {|e| if not e.nil?; res.items << e; end}
          elsif not ev.nil?
            res.items << ev
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

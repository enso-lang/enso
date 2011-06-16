

require 'core/system/load/load'
require 'core/schema/code/factory'

class EvalAttr
  IS = Loader.load('instance.schema')

  def initialize(factory)
    @factory = factory
    @memo = {}
  end

  def self.eval(obj, name, factory)
    # we assume it's an attribute field
    EvalAttr.new(factory).eval_field(name, obj)
  end

  def eval(exp, obj)
    send(exp.schema_class.name, exp, obj)
  end

  def eval_field(name, recv)
    field = recv.schema_class.fields[name]
    if field.schema_class.name == 'Attribute' then
      if field.type.Primitive? then
        # run again
        eval(field.result, recv)
      else
        if @memo[[recv, name]] then
          @memo[[recv, name]]
        else
          @memo[[recv, name]] = @factory[field.type.name]
          eval(field.result, recv)
        end
      end
    else
      recv[name]
    end
  end

  def Variable(this, recv)
    eval_field(this.name, recv)
  end

  def Dot(this, recv)
    x = eval(this.obj, recv)
    eval_field(this.field, x)
  end

  def Cons(this, recv)
    x = @factory[this.type]
    this.contents.each do |assign|
      if x.schema_class.fields[assign.name].many then
        assign.expressions.each do |exp|
          x[assign.name] << eval(exp, recv)
        end
      else
        assign.expressions.each do |exp|
          x[assign.name] = eval(exp, recv)
          break
        end
      end
    end
    return x
  end

  def IfThen(this, recv)
    c = eval(this.cond, recv)
    if c then
      eval(this.body, recv)
    else
      this.elsifs.each do |ei|
        if eval(ei.cond, recv)
          return eval(ei.body, recv)
        end
      end
      eval(this.else, recv)
    end
  end

  def Call(this, recv)
    args = this.args.map do |arg|
      eval(arg, recv)
    end
    send(this.name, *args)
  end

  def min(x, y)
    x > y ? y : x
  end

end

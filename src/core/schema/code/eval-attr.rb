

require 'core/system/load/load'
require 'core/schema/code/factory'

module AttributeSchema
  class Write
    def initialize(x, f)
      @obj = x
      @field = f
    end

    def <<(o)
      @obj[@field] = o
    end

    def value
      @obj[@field]
    end
    
    def to_s
      "write(#{@obj}.#{@field} = #{@obj[@field]}"
    end
  end

  class Result
    attr_reader :value

    def initialize(v)
      @value = v
    end

    def <<(v)
      @value = v
    end
  end

  class EvalAttr
    def initialize(factory)
      @factory = factory
      @memo = {}
    end

    def self.eval(obj, name, factory)
      # we assume name is an attribute field
      EvalAttr.new(factory).run(obj, name)
    end

    def run(obj, name)
      capture do |r|
        eval_field(name, obj, r)
      end
    end

    def eval(exp, obj, out)
      send(exp.schema_class.name, exp, obj, out)
    end

    def eval_field(name, recv, out)
      field = recv.schema_class.all_fields[name]
      return out << recv[name] if field.schema_class.name != 'Attribute'

      return eval(field.result, recv, out) if field.type.Primitive?

      key = [recv, name]
      return out << @memo[key] if @memo[key]
      return eval(field.result, recv, out) if field.many
      
      obj = @factory[field.type.name]
      @memo[key] = obj
      new = capture do |r|
        eval(field.result, recv, r)
      end
      # TODO: for fixpoints, test if the object has changed
      # if so, run this attribute again.
      obj.become!(new)
      out << obj
    end
    
    def capture(v = nil)
      r = Result.new(v)
      yield r
      r.value
    end
  

    def Variable(this, recv, out)
      eval_field(this.name, recv, out)
    end

    def Dot(this, recv, out)
      x = capture { |r| eval(this.obj, recv, r) }
      if x.is_a?(BaseManyField) then
        x.each do |elt|
          eval_field(this.field, elt, out)
        end
      else
        eval_field(this.field, x, out)
      end
    end

    def Cons(this, recv, out)
      obj = @factory[this.type]
      this.contents.each do |assign|
        assign.expressions.each do |exp|
          if obj.schema_class.fields[assign.name].many then
            eval(exp, recv, obj[assign.name])
          else
            eval(exp, recv, Write.new(obj, assign.name))
          end
        end
      end
      out << obj
    end

    def IfThen(this, recv, out)
      c = capture { |r| eval(this.cond, recv, r) }
      return eval(this.body, recv, out) if c

      this.elsifs.each do |ei|
        c = capture { |r| eval(ei.cond, recv, r) }
        return eval(ei.body, recv, out) if c
      end
      eval(this.else, recv, out)
    end

    def Call(this, recv, out)
      # apparently this reverses the list of args !?!?!?!?!?
      # args = this.args.map do |arg|
      #    capture { |r| eval(arg, recv, r) }
      #end
      args = []
      this.args.each do |arg|
        eval(arg, recv, args)
      end
      out << send(this.name, *args)
    end

    def min(*x)
      x.inject(x.first) do |cur, y|
        y < cur ? y : cur
      end
    end
  end

end

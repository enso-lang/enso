

require 'core/system/load/load'
require 'core/schema/code/factory'

module AttributeSchema
  class Write
    def initialize(x, f)
      @obj = x
      @field = f
      @many = x.schema_class.fields[f].many
    end

    def <<(o)
      if @many then
        @obj[@field] << o
      else
        @obj[@field] = o
      end
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

  # TODO: make the attributed schema a parameter
  # (for partial evaluation)

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

      # Store place holder
      obj = @memo[key] = @factory[field.type.name]
      
      # Compute new object
      new = capture { |r| eval(field.result, recv, r) }

      # TODO: for fixpoints, test if the object has changed
      # if so, run this attribute again.

      # Let placeholder become new object
      obj.become!(new)
      
      # Output it.
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
          eval(exp, recv, Write.new(obj, assign.name))
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

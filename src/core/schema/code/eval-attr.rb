

require 'core/system/load/load'
require 'core/schema/code/factory'

module AttributeSchema
  class Write
    def initialize(x, f)
      @obj = x
      @field = f
    end

    def <<(o)
      #puts "Writing #{o} to ----> #{@field} in #{@obj}"
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

  class Obj
    def initialize(o)
      @obj = obj
    end

    def value
      @obj
    end
  end

  class EvalAttr
    def initialize(factory)
      @factory = factory
      @memo = {}
    end

    def self.eval(obj, name, factory)
      # we assume name is an attribute field
      coll = []
      EvalAttr.new(factory).eval_field(name, obj, coll)
      coll.first
    end

    def eval(exp, obj, out)
      #puts ";::::::::: evaling: #{exp.schema_class.name}"
      send(exp.schema_class.name, exp, obj, out)
    end

    def bottom(type)
      case type.name
      when 'str' then ''
      when 'int' then 0
      when 'bool' then false
      else
        raise "Unsupported primitive: #{type.name}"
      end
    end

    def eval_field(name, recv, out)
      #puts "NAME: #{name}"
      #puts "recv: #{recv}"
      #puts "out: #{out}"
      field = recv.schema_class.all_fields[name]
      if field.schema_class.name == 'Attribute' then
        if field.type.Primitive? then
          #v = Result.new(bottom(field.type))
          eval(field.result, recv, out)
          #out << v.value
        else
          if @memo[[recv, name]] then
            out << @memo[[recv, name]]
          else
            if field.many then
              eval(field.result, recv, out)
            else
              obj = @factory[field.type.name]
              @memo[[recv, name]] = obj
              r = Result.new(nil)
              #puts "################## r = #{r}  value = #{r.value} OBJ = #{obj}"
              eval(field.result, recv, r)
              #puts "R>VALUE: #{r.value}"
              obj.become!(r.value)
              #puts "#####after become######### r = #{r}  value = #{r.value} OBJ = #{obj}"
              #puts "obj.kids: #{obj.kids}" if obj.schema_class.name == 'Fork'
              #puts "OUT: #{out}"
              out << obj
            end
          end
        end
      else
        
        out << recv[name]
      end
    end

    def Variable(this, recv, out)
      eval_field(this.name, recv, out)
    end

    def Dot(this, recv, out)
      #puts "DOTFIELD: #{this.field}"
      x = Result.new(nil)
      eval(this.obj, recv, x)
      #puts "DOT: #{x.value} #{x.value.class}"
      if x.value.is_a?(BaseManyField) then
        #puts "------------ A many field"
        # ugh, this must change
        i = 0
        x.value.each do |elt|
          #puts "#{i} ELT = #{elt}"
          #puts "\tOUT: #{out}"
          eval_field(this.field, elt, out)
          i += 1
        end
        #puts "Nothing added to output"
      else
        eval_field(this.field, x.value, out)
      end
    end

    def Cons(this, recv, out)
      #puts "Constructing: #{this.type}"
      #puts "OUTPUT = #{out} value = #{out.value}"
      x = @factory[this.type]
      this.contents.each do |assign|
        assign.expressions.each do |exp|
          if x.schema_class.fields[assign.name].many then
            #puts "********* Assigning to: #{assign.name}"
            eval(exp, recv, x[assign.name])
            #puts "AFTER x = #{x} &&&&&&&&&&&&&&&&&&&& #{x[assign.name]}"
          else
            eval(exp, recv, Write.new(x, assign.name))
          end
        end
      end
      out << x
    end

    def IfThen(this, recv, out)
      c = Result.new(nil)
      eval(this.cond, recv, c)
      if c.value then
        eval(this.body, recv, out)
      else
        this.elsifs.each do |ei|
          c = Result.new(nil)
          eval(ei.cond, recv, c)
          if c.value then
            eval(ei.body, recv, out)
            return
          end
        end
        eval(this.else, recv, out)
      end
    end

    def Call(this, recv, out)
      args = []
      this.args.map do |arg|
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

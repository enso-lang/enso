

require 'core/system/load/load'
require 'core/schema/code/factory'

module AttributeSchema

  # TODO: make the attributed schema a parameter
  # (for partial evaluation)

=begin


=end

  class EvalAttr
    def initialize(factory)
      @factory = factory
      @memo = {}
      @op_map = {
        '==' => 'eq',
        '!=' => 'neq',
        '>=' => 'geq',
        '<=' => 'leq',
        '>' => 'gt',
        '<' => 'lt'
      }
    end

    def self.eval(obj, name, factory)
      EvalAttr.new(factory).run(obj, name)
    end

    def run(obj, name)
      eval_access(name, obj, {}) do |x, _|
        return x
      end
    end

    def eval(exp, obj, env, &block)
      send(exp.schema_class.name, exp, obj, env, &block)
    end

    def bottom(type)
      case type.name
      when 'str' then ''
      when 'int' then 0
      when 'bool' then false
      when 'real' then 0.0
      else raise "Unsupported primitive: #{type.name}"
      end
    end

    def field(recv, name)
      recv.schema_class.all_fields[name]
    end

    def attribute?(field)
      field.schema_class.name == 'Attribute'
    end

    def debug(str)
      # $stderr << str + "\n"
    end

    def eval_access(name, recv, env, &block)
      fld = field(recv, name)
      raise "No such field or attribute: #{name}" unless fld

      debug "FIELD ACCESS: #{fld.name} on #{recv}"
      if attribute?(fld) then
        eval_attribute(fld, recv, env, &block)
      else
        eval_normal_field(fld, recv, env, &block) 
      end
    end

    def eval_normal_field(field, recv, env, &block)
      debug "normal field: #{field.name}"
      x = recv[field.name]
      if x.class.include?(Enumerable) then
        x.each do |elt|
          yield elt, env
        end
      else
        yield x, env
      end
    end

    def eval_attribute(field, recv, env, &block)
      if field.type.Primitive? then
        eval_primitive_attribute(field, recv, env, &block)
      else
        eval_object_attribute(field, recv, env, &block)
      end
    end


    def eval_primitive_attribute(field, recv, env, &block)
      eval(field.result, recv, env, &block)
#       debug "prim attr: #{field.name}"
#       key = [recv, field.name]
#       if @memo[key] then
#         yield @memo[key], env
#       else
#         # todo: field.init
#         @memo[key] = bottom(field.type)
#         eval(field.result, recv, env) do |x, env|
#           @memo[key] = x
#           yield x, env
#         end 
#       end
    end

    def eval_object_attribute(field, recv, env, &block)
      debug "obj attr #{field.name}"
      if field.many then
        eval(field.result, recv, env, &block)
      else
        key = [recv, field.name]
        if @memo[key] then
          yield @memo[key], env
        else
          obj = @memo[key] = @factory[field.type.name]        
          eval(field.result, recv, env) do |new, env|
            obj.become!(new)
            break # ???
          end
          yield obj, env
        end
      end
    end



    def eval_conds(conds, recv, env, &block)
      head = conds[0]

      if conds.length == 1 then
        eval(head, recv, env) do |x, env|
          yield x, env if x
        end
      else
        tail = list[1..-1]
        eval(head, recv, env) do |x, env|
          eval_conds(tail, recv, env, &block) if x
        end
      end
    end

    def eval_args(list, recv, env, &block)
      return yield [], env if list.empty?
      
      head = list[0]
      tail = list[1..-1]

      eval(head, recv, env) do |x, env|
        eval_args(tail, recv, env) do |xs, env|
          yield [*x, *xs], env
        end
      end
    end



    def eval_seq(exps, recv, env, &block)
      exps.each do |exp|
        eval(exp, recv, env, &block)
      end
    end

    def eval_local(val, env, &block)
      if val.is_a?(Delayed) then
        val.force(env, &block)
      elsif val.class.include?(Enumerable) then
        val.each do |elt|
          yield elt, env
        end
      else
        yield val, env
      end
    end

    #### Dispatch methods
    
    def Variable(this, recv, env, &block)
      return eval_local(env[this.name], env, &block) if env[this.name]
      eval_access(this.name, recv, env, &block)
    end

    def Dot(this, recv, env, &block)
      eval(this.obj, recv, env) do |x, env|
        eval_access(this.field, x, env, &block)
      end
    end

    def Cons(this, recv, env, &block)
      obj = @factory[this.type]
      this.contents.each do |assign|
        assign.expressions.each do |exp|
          eval(exp, recv, env) do |val, _|
            if obj[assign.name].is_a?(BaseManyField) then
              obj[assign.name] << val
            else
              obj[assign.name] = val
            end
          end
        end
      end
      yield obj, env
    end

    def For(this, recv, env, &block)
      eval_conds(this.conds, recv, env) do |_, env|
        eval_seq(this.body, recv, env, &block)
      end
    end

    def IfThen(this, recv, env, &block)
      eval_conds(this.conds, recv, env) do |_, env|
        return eval_seq(this.body, recv, env, &block) 
      end

      this.elsifs.each do |ei|
        eval_conds(ei.conds, recv, env) do |_, env|
          return eval_seq(ei.body, recv, env, &block) 
        end
      end
      eval_seq(this.else.body, recv, env, &block)
    end

    def Splat(this, recv, env, &block)
      args = []
      eval(this.arg, recv, env) do |x, env|
        args << x
      end
      yield args, env
    end

    def Call(this, recv, env, &block)
      fld = field(recv, this.name)
      if fld && attribute?(fld) then
        eval_args(this.args, recv, env) do |args, env|
          new_env = {}.update(env)
          field.formals.each_with_index do |frm, i|
            new_env[frm.name] = args[i]
          end
          # todo: move formals stuff to eval_attribute
          # since it should do memoization on arguments too
          eval_attribute(fld, recv, new_env, &block)
        end
      else
        eval_args(this.args, recv, env) do |args, env|
          yield send(this.name, *args), env
        end
      end
    end

    class Delayed
      def initialize(factory, eval, binding, recv, env)
        @factory = factory
        @eval = eval
        @binding = binding
        @recv = recv
        @env = env
        @env[name] = self
      end

      def name
        @binding.name
      end

      def force(env, &block)
        bind!
        yield @env[name], env
      end

      def bind!
        # already bound
        return if @env[name] != self

        if @binding.type.Primitive?
          @eval.eval(@binding.exp, @env) do |x, _|
            @env[@binding.name] = x
          end
        elsif @binding.many then
          # we don't have collection literals
          # so any valid expression here should
          # return a BaseManyField; however,
          # evaluating such a thing will enumerate over
          # its elements. So we use an ordinary array.
          # if the binding is used in any context
          # there will be iteration.
          @env[@binding.name] = []
          @eval.eval(@exp, @recv, @env) do |x, env|
            @env[@binding.name] << x
          end
        else
          obj = @factory[binding.type.name]
          @env[@binding.name] = obj
          @eval.eval(@exp, @recv, @env) do |x, env|
            obj.become!(x)
          end
        end
      end
    end

    def Let(this, recv, env, &block)
      env = {}.update(env)
      this.bindings.each do |b|
        Delayed.new(@factory, self, b, recv, env)
      end
      this.bindings.each do |b|
        env[b.name].bind!
      end
      eval(this.body, recv, env, &block)
    end

    def Generator(this, recv, env, &block)
      eval(this.exp, recv, env) do |x, env|
        yield true, env.update({this.name => x})
      end
    end

    def Unary(this, recv, env, &block)
      eval(this.arg, recv, env) do |arg, _|
        yield send(@op_map[this.op], arg), env
      end
    end

    def Binary(this, recv, env, &block)
      eval(this.lhs, recv, env) do |lhs, _|
        eval(this.rhs, recv, env) do |rhs, _|
          yield send(@op_map[this.op], lhs, rhs), env
        end
      end
    end

    # operators and functions

    def eq(a, b)
      a == b
    end

    def min(*x)
      x.inject(x.first) do |cur, y|
        y < cur ? y : cur
      end
    end
  end

end

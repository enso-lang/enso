

require 'core/system/load/load'
require 'core/schema/code/factory'

require 'core/schema/tools/union'
require 'core/schema/tools/copy'

require 'core/system/library/schema'


=begin 

 - primitives: update memo table while successive results are different

 - objects: become! until the computed object is shallow_equal to the
   object of the previous iteration

 - collections: for keyed collections, only add an element if an
   object with the same key does not already exist. If it does exist,
   let the existing object become the new one. For sequential collections
   a new object is always added.

=end

module AttributeSchema

  # TODO: make the attributed schema a parameter
  # (for partial evaluation)

  class EvalAttr

    def initialize(factory)
      @factory = factory
      @CHANGE = false
      @IN_CIRCLE = false
      @memo = {}
      @computed = {}
      @visited = {}
      @op_map = {
        '==' => 'eq',
        '!=' => 'neq',
        '>=' => 'geq',
        '<=' => 'leq',
        '>' => 'gt',
        '<' => 'lt',
        '+' => 'add'
      }
    end

    def self.eval(obj, name, factory, args = [])
      EvalAttr.new(factory).run(obj, name, args)
    end

    def debug_info
      puts "COMPUTED:"
      @computed.each do |k, v|
        puts "\t#{k}: #{v}"
      end
      puts "MEMO:"
      @memo.each do |k, v|
        puts "\t#{k}: #{v}"
      end
      puts "VISITED:"
      @visited.each do |k, v|
        puts "\t#{k}: #{v}"
      end
      puts "INCIRCLE: #{@IN_CIRCLE}"
      puts "CHANGE: #{@CHANGE}"
    end


    def self.eval_attr_schema(attr_schema, src, name,
                              src_schema = nil, trg_schema = nil, args = [])
      u = attr_schema
      u = union(u, src_schema) if src_schema
      u = union(u, trg_schema) if trg_schema
      src = Copy.new(Factory.new(u)).copy(src)
      eval(src, name, Factory.new(u), args)
    end

    def run(obj, name, args)
      attr = field(obj, name)
      eval_attribute(attr, obj, {}, args) do |x, _|
        return x
      end
    end

    def eval(exp, obj, env, &block)
      #debug_info
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

    def eval_access(name, recv, env, &block)
      fld = field(recv, name)
      raise "No such field or attribute: #{name}" unless fld

      if attribute?(fld) then
        eval_attribute(fld, recv, env, &block)
      else
        eval_normal_field(fld, recv, env, &block) 
      end
    end

    def eval_normal_field(field, recv, env, &block)
      x = recv[field.name]
      if x.class.include?(Enumerable) then
        x.each do |elt|
          yield elt, env
        end
      else
        yield x, env
      end
    end

    def eval_attribute(attr, recv, env, args = [], &block)
      if attr.type.Primitive? 
        eval_primitive_attribute(attr, recv, env, args, &block)
      elsif attr.many then
        eval_collection_attribute(attr, recv, env, args, &block)
      else
        eval_object_attribute(attr, recv, env, args, &block)
      end
    end

    def eval_primitive_attribute(attr, recv, env, args, &block)
      key = [recv, attr.name, args]
      if @computed[key] then
        yield @memo[key], env
        return
      end
      new_env = bind_formals(attr, env, args)
      @memo[key] ||= attr.default && attr.default.value  # INIT
      if !@IN_CIRCLE then
        @IN_CIRCLE = true
        @visited[key] = true
        begin
          @CHANGE = prim_iter(@memo, key, attr, recv, new_env)
        end while @CHANGE
        @visited[key] = false
        @computed[key] = true
        @IN_CIRCLE = false
      elsif !@visited[key] then
        @visited[key] = true
        @CHANGE = prim_iter(@memo, key, attr, recv, new_env)
        @visited[key] = false
      end
      yield @memo[key], env # RETURN
    end

    def prim_iter(tbl, key, attr, recv, env) 
      eval(attr.result, recv, env) do |new, _|
        if new != tbl[key] then
          tbl[key] = new
          return true
        end
        return false
      end
    end
          

    def yield_all(coll, env, &block)
      coll.each do |elt|
        yield elt, env
      end
    end

    def eval_collection_attribute(attr, recv, env, args, &block)
      key = [recv, attr.name, args]
      if @computed[key] then
        return yield_all(@memo[key], env, &block)
      end

      new_env = bind_formals(attr, env, args)
      @memo[key] ||= []  # INIT
      if !@IN_CIRCLE then
        @IN_CIRCLE = true
        @visited[key] = true
        begin
          @CHANGE = coll_iter(@memo[key], attr, recv, new_env)
        end while @CHANGE
        @visited[key] = false
        @computed[key] = true
        @IN_CIRCLE = false
      elsif !@visited[key] then
        @visited[key] = true
        @CHANGE = coll_iter(@memo[key], attr, recv, new_env)
        @visited[key] = false
      end
      yield_all(@memo[key], env, &block) # RETURN
    end

    def coll_iter(coll, attr, recv, env) 
      change = false
      eval(attr.result, recv, env) do |new, _|
        key_field = ClassKey(new.schema_class)
        if key_field then
          found = coll.find { |x| x[key_field.name] == new[key_field.name] }
          if !found then
            change = true
            coll << new
          else
            if !found.shallow_equal?(new) then
              change = true
              found.become!(new)
            end
          end
        else
          # Problem: with the schema2graph example
          # needs composite keys...
          # this is wrong now: it assumes lists are sets.
          unless coll.find { |x| x.shallow_equal?(new) }
            coll << new
          end
        end
      end
      return change
    end


    def eval_object_attribute(attr, recv, env, args, &block)
      key = [recv, attr.name, args]
      if @computed[key] then
        yield @memo[key], env
        return
      end

      new_env = bind_formals(attr, env, args)
      @memo[key] ||= Stub.new  # INIT
      if !@IN_CIRCLE then
        @IN_CIRCLE = true
        @visited[key] = true
        begin
          @CHANGE = obj_iter(@memo[key], attr, recv, new_env)
        end while @CHANGE
        @visited[key] = false
        @computed[key] = true
        @IN_CIRCLE = false
      elsif !@visited[key] then
        @visited[key] = true
        @CHANGE = obj_iter(@memo[key], attr, recv, new_env)
        @visited[key] = false
      end
      yield @memo[key], env # RETURN
    end
          
    def obj_iter(obj, attr, recv, env)
      eval(attr.result, recv, env) do |new, _|
        if !obj.shallow_equal?(new) then
          obj.become!(new) # UPDATE
          return true
        end
      end
      return false
    end




    def eval_conds(conds, recv, env, &block)
      eval(conds.first, recv, env) do |x, env|
        return unless x
        if conds.length == 1 then
          yield x, env
        else
          eval_conds(conds[1..-1], recv, env, &block)
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

    def bind_formals(attr, env, args)
      env = {}.update(env)
      attr.formals.each_with_index do |frm, i|
        env[frm.name] = args[i]
      end
      return env
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
      #puts "CREATING: #{this.type}"
      obj = @factory[this.type]
      this.contents.each do |assign|
        assign.expressions.each do |exp|
          eval(exp, recv, env) do |val, _|
            #puts "Adding #{val} to field: #{assign.name} of #{obj}"
            if obj[assign.name].is_a?(BaseManyField) then
              # TODO: only test for include if keyed
              #if !obj[assign.name].include?(val) then
              obj[assign.name] << val
              #end
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
          eval_attribute(fld, recv, env, args, &block)
        end
      else
        eval_args(this.args, recv, env) do |args, env|
          yield send(this.name, *args), env
        end
      end
    end

    class Delayed
      # Lazy bindings that self-destruct into values
      # they evaluate to

      def initialize(eval, binding, recv, env)
        @eval = eval
        @binding = binding
        @recv = recv
        @env = env
      end

      def name
        @binding.name
      end

      def force(env, &block)
        # no need to check whether
        # we should evaluate or not
        # since the Delayed thing is replaced
        # with what it evaluates to for caching

        if @binding.many then
          # don't cache (for now)
          @eval.eval(@binding.expression, @recv, @env) do |x, _|
            yield x, env
          end
        else
          obj = Stub.new
          @env[name] = obj
          @eval.eval(@binding.expression, @recv, @env) do |x, _|
            # detect stuff like "let x = x"
            raise "cycle without construction" if x.is_a?(Stub)
            obj.become!(x)            
          end
          yield obj, env
        end
      end
    end

    def Let(this, recv, env, &block)
      env = {}.update(env)
      this.bindings.each do |binding|
        env[binding.name] = Delayed.new(self, binding, recv, env)
      end
      eval_seq(this.body, recv, env, &block)
    end

    def Generator(this, recv, env, &block)
      env = {}.update(env)
      eval(this.expression, recv, env) do |x, _|
        yield true, env.update({this.var => x})
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

    def Str(this, recv, env, &block)
      yield this.value, env
    end

    def Int(this, recv, env, &block)
      yield this.value, env
    end

    def Bool(this, recv, env, &block)
      yield this.value, env
    end

    # operators and functions

    def eq(a, b) a == b; end

    def add(a, b) a + b; end

    def gt(a, b) a > b; end

    def lt(a, b) a < b; end

    def geq(a, b) a >= b; end

    def leq(a, b) a <= b; end
      

    def min(*x)
      x.inject(x.first) do |cur, y|
        y < cur ? y : cur
      end
    end
    
    def odd(x)
      x % 2 != 0
    end
    

    def sum(*x)
      x.inject(0, &:+)
    end
  end

end

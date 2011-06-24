

require 'core/system/load/load'
require 'core/schema/code/factory'

require 'core/schema/tools/union'
require 'core/schema/tools/copy'

require 'core/system/library/schema'


=begin 

 - primitives: update memo table while successive results are different

 - objects: become! until the computed object is semantic_equal? to the
   object of the previous iteration

 - collections: for keyed collections, only add an element if an
   object with the same key does not already exist. If it does exist,
   let the existing object become the new one. For sequential
   collections a new object is always added. (This is why the
   schema2graph trafo currently does not terminate: edges have no keys).

Misc notes:

- sum over a cyclic graph diverges if fixing: the value of sum keeps 
  increasing. It is not a fix point: sum should return zero upon *any*
  revisit of a node, not just upon the first cycle.

- If object attrs are not fixed, fixpoints only work on collections
  Do we want to specify fix behaviour explicitly? Sum still diverges.
  

- Letrec does not work yet

- Transitive closure: this works, because the init of Node* is empty
  @trc: Node* = Node {name: name; value: value; out: out, out->trc->out }

  but this doesn't: error when trying to evaluate trc on a stub
  when hitting a cycle:

  @trc: Node = Node {name: name; value: value; out: out, out->trc->out }

  Should there be an init like: Node {name: name; value: value; out: }????  

- This does not terminate: again because where accessing something
  (through a cycle) that has not been created yet

   @mul2: Node = Node {name: name; value: value * 2; out: out->mul2}

  Again, this works:

  @mul2: Node* = Node {name: name; value: value * 2; out: out->mul2}



Todos

- make the attributed schema a parameter
  (for partial evaluation)

- Replace ; with comma ,

- Allow ; as toplevel attribute expression

- there's still abug somewhere that makes the factory complain:
  inserting into the wrong model. Have to add  copying when this happens. 
  but it will be a full copy...

- All the is_a? stuff should be gone (except maybe for internal
  stuff), and the schema should be used.

- Clearing of collections does not update inverses.
=end

module AttributeSchema

  class EvalAttr

    def initialize(attr_schema, factory)
      @attr_schema = attr_schema
      @factory = factory
      @CHANGE = false
      @IN_CIRCLE = false
      @memo = {}
      @computed = {}
      @visited = {}
    end

=begin

X -> X : factory should be the factory of the source
X -> Y : factory should be  the factory of the target
X -> X + Y: factory should be a factory over X + Y *and*
        X should be copied first using that factory.
=end

    def self.eval(attr_schema, obj, name, factory = obj._graph_id, args = [])
      EvalAttr.new(attr_schema, factory).run(obj, name, args)
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
      ac = @attr_schema.classes[recv.schema_class.name]
      fld = ac.fields[name]
      #puts "Requesting field #{name} of #{recv}"
      #Print.print(recv)
      #Print.print(recv.schema_class)
      fld || recv.schema_class.all_fields[name]
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
      if field.many then
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
            if !found.semantic_equal?(new) then
              change = true
              found.become!(new)
            end
          end
        else
          # Problem: with the schema2graph example
          # needs composite keys...
          # the unless solution is wrong: it assumes lists are sets.
          #unless coll.find { |x| x.semantic_equal?(new) }
            coll << new
          #end
        end
      end
      return change
    end

    module Uniqueness
      def ==(o)
        object_id == o.object_id
      end

      def hash
        object_id
      end
    end

    class KeyString < String
      include Uniqueness
      def to_s
        "UNIQUE_KEY_#{object_id}"
      end
    end

    def placeholder(type)
      obj = @factory[type.name]  # INIT
      k = ClassKey(obj.schema_class)
      if k then
        # TODO: for each type
        # it's ugly, but seems to work.
        obj[k.name] = case k.type.name
                      when 'str' then KeyString.new
                      when 'int' then KeyInt.new
                      when 'bool' then KeyBool.new
                      when 'real' then KeyReal.new
                      else raise "Unsupported primitive: #{k.type}"
                      end
      end
      return obj
    end

    def eval_object_attribute(attr, recv, env, args, &block)
      key = [recv, attr.name, args]

      if @computed[key] then
        yield @memo[key], env
        return
      end

      new_env = bind_formals(attr, env, args)
      if !@memo[key] then
        @memo[key] = placeholder(attr.type)
      end
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
        if !obj.semantic_equal?(new) then
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
      if val.class.include?(Enumerable) then
        val.each do |elt|
          yield elt, env
        end
      else
        yield val, env
      end
    end

    def eval_assigns(obj, contents, recv, env, &block)
      contents.each do |assign|
        assign.expressions.each do |exp|
          eval(exp, recv, env) do |val, _|
            if obj.schema_class.fields[assign.name].many then
              obj[assign.name] << val
            else
              obj[assign.name] = val
            end
          end
        end
      end
      yield obj, env
    end

    def updates(fields, contents, recv, env)
      updates = {}
      contents.each do |assign|
        if assign.expressions.empty? then
          if fields[assign.name].many then
            updates[assign.name] = :clear
          else
            updates[assign.name] = :delete
          end
        else
          assign.expressions.each do |exp|
            eval(exp, recv, env) do |val, _|
              if fields[assign.name].many then
                updates[assign.name] ||= []
                updates[assign.name] << val
              else
                updates[assign.name] = val
              end
            end
          end
        end
      end
      return updates
    end

    def apply_updates(obj, changes)
      changes.each do |fname, x|
        if x == :clear then
          obj[fname].clear
        elsif x == :delete
          obj[fname] = nil
        elsif x.is_a?(Array)
          x.each do |elt|
            obj[fname] << elt
          end
        else
          obj[fname] = x
        end
      end
    end

    #### Dispatch methods
    
    def Variable(this, recv, env, &block)
      if this.name == 'self' then
        yield recv, env
      elsif env[this.name] then
        eval_local(env[this.name], env, &block) 
      else 
        eval_access(this.name, recv, env, &block)
      end
    end

    def Dot(this, recv, env, &block)
      eval(this.obj, recv, env) do |x, env|
        eval_access(this.field, x, env, &block)
      end
    end
    
    def Lookup(this, recv, env, &block)
      eval(this.obj, recv, env) do |x, env|
        eval(this.key, recv, env) do |f, env|
          eval_access(f, x, env, &block)
        end
      end
    end


    def Update(this, recv, env, &block)
      eval(this.obj, recv, env) do |obj, env|
        changes = updates(obj.schema_class.fields, this.contents, recv, env)
        apply_updates(obj, changes)
        yield obj, env
      end
    end


    def Cons(this, recv, env, &block)
      obj = @factory[this.type]
      eval_assigns(obj, this.contents, recv, env, &block)
    end

    def Not(this, recv, env, &block)
      eval(this.arg, recv, env) do |_, _|
        return
      end
      yield true, env
    end

    def For(this, recv, env, &block)
      eval_conds(this.conds, recv, env) do |_, env|
        eval_seq(this.body, recv, env, &block)
      end
    end

    def IfThen(this, recv, env, &block)
      eval_conds(this.conds, recv, env) do |x, env|
        return eval_seq(this.body, recv, env, &block) 
      end
      this.elsifs.each do |ei|
        eval_conds(ei.conds, recv, env) do |_, env|
          return eval_seq(ei.body, recv, env, &block) 
        end
      end
      eval_seq(this.else.body, recv, env, &block) if this.else
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
      eval_args(this.args, recv, env) do |args, env|
        if fld && attribute?(fld) then
          eval_attribute(fld, recv, env, args, &block)
        else
          yield send(this.name, *args), env
        end  
      end
    end

    def Generator(this, recv, env, &block)
      env = {}.update(env)
      eval(this.expression, recv, env) do |x, _|
        yield x, env.update({this.var => x})
      end
    end

    def Unary(this, recv, env, &block)
      eval(this.arg, recv, env) do |arg, _|
        yield arg.send(this.op), env
      end
    end

    def Binary(this, recv, env, &block)
      eval(this.lhs, recv, env) do |lhs, _|
        eval(this.rhs, recv, env) do |rhs, _|
          yield lhs.send(this.op, rhs), env
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



require 'core/web/code/dispatch'
require 'core/web/code/renderable'


module Web::Eval
  class Expr
    include Dispatch

    def initialize(store, log, actions)
      @store = store
      @log = log
      @gensym = 0
      @actions = actions
    end

    def Str(this, env, errors)
      Result.new(this.value)
    end

    def Int(this, env, errors)
      Result.new(Integer(this.value))
    end

    def Var(this, env, errors)
      @log.debug("VAR: #{this.name}")
      # @log.debug("ENV = #{env}")
      if this.name == 'errors' then
        Result.new(errors)
      elsif this.name == 'gensym' then
        @gensym += 1
        Result.new("$$#{@gensym}")        
      elsif env[this.name] then
        @log.debug("ENV VAR: #{env[this.name]}")
        env[this.name] 
      elsif @actions.respond_to?(this.name) then
        # yikes, ruby methods as values
        Result.new(@actions.method(this.name))
      else
        @log.warn("Undefined variable: #{this.name.inspect}")
        @log.debug("ENV = #{env}")
        return nil
      end
    end

    def Concat(this, env, errors)
      lhs = eval(this.lhs, env, errors)
      rhs = eval(this.rhs, env, errors)
      Result.new(lhs.value.to_s + rhs.value.to_s)
    end

    def Equal(this, env, errors)
      lhs = eval(this.lhs, env, errors)
      rhs = eval(this.rhs, env, errors)
      Result.new(lhs.value == rhs.value)
    end

    def In(this, env, errors)
      lhs = eval(this.lhs, env, errors)
      rhs = eval(this.rhs, env, errors) 
      rhs.value.each do |x|
        if lhs.value == x then
          return Result.new(true)
        end
      end
      Result.new(false)
    end

    def Address(this, env, errors)
      r = eval(this.exp, env, errors)
      path = r.path
      @log.debug("Evaluating path of result #{r}: '#{path}'")
      # @log.debug("ENV = #{env}")
      @log.warn("Address asked, but path is nil (val = #{path})") if path.nil?
      Result.new(path)
    end

    def New(this, env, errors)
      Result.new(*@store.create(this.class))
    end

    def Field(this, env, errors)
      r = eval(this.exp, env, errors)
      # TODO: get rid of &&
      puts "NAME = #{this.name}"
      Result.new(r.value[this.name], r.path && r.path.descend_field(this.name))
    end

    def Subscript(this, env, errors)
      obj = eval(this.obj, env, errors)
      @log.debug("OBJ = #{obj}")
      sub = eval(this.exp, env, errors)
      @log.debug("SUB = #{sub}")
      # TODO: get rid of &&
      r = Result.new(obj.value[sub.value], obj.path && 
                 obj.path.descend_collection(sub.value))
      @log.debug("Returning subscript result: #{r}")
      return r
    end

    def Call(this, env, errors)
      callable = eval(this.exp, env, errors).value
      args = this.args.map do |arg|
        eval(arg, env, errors)
      end
      
      @log.warn("CALLABLE = #{callable} + args = #{args}")

      if callable.is_a?(Method) then # a controller action
        Action.new(callable, nil, args)
      elsif callable.is_a?(Function) then
        Link.new(callable, args)
      else
        @log.warn("Cannot call: #{callable}")
      end
    end

    def List(this, env, errors)
      this.elements.map do |elt|
        eval(elt, env, errors)
      end
    end

  end
end

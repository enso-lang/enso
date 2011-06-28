

require 'core/web/code/renderable'

class EvalExp
  attr_reader :log

  def initialize(root, actions, log)
    @root = root
    @actions = actions
    @gensym = 0
    @new_count = 0
    @log = log
  end

  def eval(obj, *args)
    send(obj.schema_class.name, obj, *args)
  end
  
  def Str(this, env)
    Result.new(this.value)
  end

  def Int(this, env)
    Result.new(Integer(this.value))
  end

  def Var(this, env)
    log.debug("VAR: #{this.name}")
    if env[this.name] then
      env[this.name] # env binds results
    elsif @actions.respond_to(this.name) then
      # change this to explicit object?
      Result.new(this.name.to_sym)
    elsif this.name == 'root'
      Result.new(@root, '')
    else
      log.warn("Unbound variable #{this.name} or action (env = #{env})")
    end
  end

  def GenSym(this, env)
    @gensym += 1
    Result.new("$$#{@gensym}")
  end

  def Concat(this, env)
    lhs = eval(this.lhs, env)
    rhs = eval(this.rhs, env)
    Result.new(lhs.value + rhs.value)
  end

  def Equal(this, env)
    lhs = eval(this.lhs, env)
    rhs = eval(this.rhs, env)
    Result.new(lhs.value == rhs.value)
  end

  def In(this, env)
    lhs = eval(this.lhs, env)
    rhs = eval(this.rhs, env) 
    rhs.value.each do |x|
      if lhs.value == x then
        return Result.new(true)
      end
    end
    Result.new(false)
  end

  def Address(this, env)
    path = eval(this.exp, env).path
    if path then
      Result.new(path)
    else
      log.warn("Address asked, but path is nil (val = #{r.value})") 
    end
  end

  def New(this, env)
    id = @new_count += 1;
    path = "@#{this.class}:#{id}"
    new_obj = @root._graph_id[this.class]
    Result.new(new_obj, path)
  end

  def Field(this, env)
    r = eval(this.exp, env)
    Result.new(r.value[this.name], "#{r.path}.#{this.name}")
  end

  def Subscript(this, env)
    obj = eval(this.obj, env)
    sub = eval(this.exp, env)
    Result.new(obj.value[sub.value], "#{obj.path}.#{sub.value}")
  end

  def Call(this, env)
    callable = eval(this.exp, env).value
    args = this.args.map do |arg|
      eval(arg, env)
    end

    if callable.is_a?(Symbol) then # an action
      Action.new(callable, args)
    elsif callable.is_a?(Closure) then
      Link.new(callable, args)
    else
      log.warn("Cannot call: #{callable}")
    end
  end

  def List(this, env)
    this.elements.map do |elt|
      eval(elt, env)
    end
  end

end

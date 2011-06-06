


class Result
  attr_reader :value, :path
  
  def initialize(value, path = nil)
    @value = value
    @path = path
  end
  
  def to_s
    "<#{value}, #{path}>"
  end
end


class EvalExp
  attr_reader :log

  def initialize(root, log)
    @root = root
    @gensym = 0
    @new_count = 0
    @log = log
  end

  def eval(obj, *args)
    send(obj.schema_class.name, obj, *args)
  end
  
  def Link(this, env)
    r = eval(this.exp, env)
    name, formals, *args = r.value

    # TODO: check for inconsistent "calls" here (e.g. no cons and tail args)

    params = []      
    formals.each_with_index do |frm, i|
      arg = args[i].path || args[i].value
      params << "#{frm.name}=#{URI.escape(arg)}"
    end

    return Result.new(name) if params.empty?
    return Result.new("#{name}?#{params.join('&')}")
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
    elsif this.name == 'root'
      Result.new(@root, '')
    else
      log.warn("Unbound variable #{this.name} (env = #{env})")
      nil
    end
  end

  def GenSym(this, env)
    @gensym += 1
    return Result.new("$$#{@gensym}")
  end

  def Concat(this, env)
    lhs = eval(this.lhs, env)
    rhs = eval(this.rhs, env)
    return Result.new(lhs.value + rhs.value)
  end

  def Equal(this, env)
    lhs = eval(this.lhs, env)
    rhs = eval(this.rhs, env)
    return Result.new(lhs.value == rhs.value)
  end

  def In(this, env)
    lhs = eval(this.lhs, env)
    rhs = eval(this.rhs, env) 
    rhs.value.each do |x|
      if lhs.value == x then
        return Result.new(true)
      end
    end
    return Result.new(false)
  end

  def Address(this, env)
    r = eval(this.exp, env)
    log.warn("Address asked, but path is nil (val = #{r.value})") unless r.path
    return Result.new(r.path)
  end

  def New(this, env)
    id = @new_count += 1;
    path = "@#{this.class}:#{id}"
    new_obj = @root._graph_id[this.class]
    return Result.new(new_obj, path)
  end

  def Field(this, env)
    r = eval(this.exp, env)
    #log.debug "---------------> Field: #{r} #{this.name}"
    x = Result.new(r.value[this.name], "#{r.path}.#{this.name}")
    log.debug "XXX = #{x}"
    return x
  end

  def Subscript(this, env)
    obj = eval(this.obj, env)
    sub = eval(this.exp, env)
    x = Result.new(recv.value[sub.value], "#{obj.path}.#{sub.value}")
  end

  def Call(this, env)
    vs = this.args.map do |arg|
      eval(arg, env)
    end
    r = eval(this.exp, env)
    clos = r.value
    return unless clos
    Result.new([clos.name, clos.formals, *vs])
  end

  def List(this, env)
    vs = this.elements.each do |elt|
      eval(elt, env)
    end
  end

end

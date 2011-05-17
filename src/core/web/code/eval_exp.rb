

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


  def initialize(root)
    @root = root
    @gensym = 0
    @new_count = 0
  end

  def eval(obj, *args)
    send(obj.schema_class.name, obj, *args)
  end
  
  def Link(this, tenv, env)
    r = eval(this.exp, tenv, env)
    func, *args = r.value

    params = []      
    func.formals.each_with_index do |frm, i|
      arg = args[i].path || args[i].value
      params << "#{frm.name}=#{URI.escape(arg)}"
    end

    return Result.new(func.name) if params.empty?
    return Result.new("#{func.name}?#{params.join('&')}")
  end
  

  def Str(this, tenv, env)
    Result.new(this.value)
  end

  def Int(this, tenv, env)
    Result.new(Integer(this.value))
  end

  def Var(this, tenv, env)
    puts "ENV = #{env}"
    if env[this.name] then
      env[this.name] # env binds results
    elsif this.name == 'root'
      Result.new(@root, '')
    else
      raise "No such variable: #{this.name}"
    end
  end

  def GenSym(this, tenv, env)
    @gensym += 1
    return Result.new("$$#{@gensym}")
  end

  def Concat(this, tenv, env)
    lhs = eval(this.lhs, tenv, env)
    rhs = eval(this.rhs, tenv, env)
    return Result.new(lhs.value + rhs.value)
  end

  def Equal(this, tenv, env)
    lhs = eval(this.lhs, tenv, env)
    rhs = eval(this.rhs, tenv, env)
    return Result.new(lhs.value == rhs.value)
  end

  def In(this, tenv, env)
    lhs = eval(this.lhs, tenv, env)
    rhs = eval(this.rhs, tenv, env) 
    rhs.value.each do |x|
      if lhs.value == x then
        return Result.new(true)
      end
    end
    return Result.new(false)
  end

  def Address(this, tenv, env)
    r = eval(this.exp, tenv, env)
    return Result.new(r.path)
  end

  def New(this, tenv, env)
    id = @new_count += 1;
    path = "@#{this.class}:#{id}"
    # don't finalize here
    new_obj = @root._graph_id[this.class]
    return Result.new(new_obj, path)
  end

  def Field(this, tenv, env)
    r = eval(this.exp, tenv, env)
    puts "---------------> Field: #{r} #{this.name}"
    x = Result.new(r.value[this.name], "#{r.path}.#{this.name}")
    puts "XXX = #{x}"
    return x
  end

  def Call(this, tenv, env)
    vs = this.args.map do |arg|
      eval(arg, tenv, env)
    end
    Result.new([tenv[this.func], *vs])
  end

  def List(this, tenv, env)
    vs = this.elements.each do |elt|
      eval(elt, tenv, env)
    end
  end

end

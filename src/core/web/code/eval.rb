
require 'htmlentities'
require 'uri'

class EvalWeb
  
  class EvalExp

    def initialize(root)
      @root = root
    end

    def eval(obj, *args)
      send(obj.schema_class.name, obj, *args)
    end
    
    def Link(this, tenv, env)
      func, *args = eval(this.exp, tenv, env)
      params = []
      func.formals.each_with_index do |frm, i|
        params << "#{frm.name}=#{URI.escape(args[i])}"
      end
      return func.name if params.empty?
      return "#{func.name}?#{params.join('&')}"
    end
      

    def Str(this, tenv, env)
      this.value
    end

    def Var(this, tenv, env)
      puts env
      puts this.name
      env[this.name]
    end

    def Field(this, tenv, env)
      obj = eval(this.exp, tenv, env)
      puts "---------------> Field: #{obj} #{this.name}"
      obj[this.name]
    end

    def All(this, tenv, env)
      x = @root.schema_class.schema.classes[this.klass]
      # should have generic thing to iterate all things from root
      @root.classes.select do |y|
        y.schema_class == x
      end
    end

    def Call(this, tenv, env)
      vs = this.args.map do |arg|
        eval(arg, tenv, env)
      end
      [tenv[this.func], *vs]
    end

  end

  class Closure
    attr_reader :env, :body
    def initialize(env, body)
      @env = env
      @body = body
    end
  end

  def initialize(web, root)
    @web = web
    @root = root
    @tenv = {}
    web.defs.each do |f|
      @tenv[f.name] = f
    end
    puts @tenv
    @coder = HTMLEntities.new
    @exp_eval = EvalExp.new(root)
  end

  def eval(obj, *args)
    send(obj.schema_class.name, obj, *args)
  end

  def defines?(name)
    @tenv[name]
  end
  
  def eval_req(name, params, out)
    eval(@tenv[name].body, params, out, nil)
  end
  
  def Element(this, env, out, block)
    out << "<#{this.tag}"
    this.attrs.each do |attr|
      out << ' ' 
      val = @coder.encode(@exp_eval.eval(attr.exp, @tenv, env))
      out << "#{attr.name}=\"#{val}\""
    end
    out << ">"
    this.body.each do |stat|
      eval(stat, env, out, block)
    end
    out << "</#{this.tag}>"
  end

  def Output(this, env, out, block)
    v = @exp_eval.eval(this.exp, @tenv, env)
    out << @coder.encode(v)
  end

  def For(this, env, out, block) 
    vs = @exp_eval.eval(this.iter, @tenv, env)
    nenv = {}.update(env)
    vs.each_with_index do |v, i|
      nenv[this.var] = v
      nenv[this.index] = i if this.index
      eval(this.body, nenv, out, block)
    end
  end

  def If(this, env, out, block)
  end

  def Call(this, env, out, block)
    f = @tenv[this.func]
    vs = this.args.map do |exp|
      puts "Evaluating #{exp}"
      r = @exp_eval.eval(exp, @tenv, env)
      puts "REsult = #{r}"
      r
    end
    nenv = {}.update(env)
    f.formals.each_with_index do |frm, i|
      nenv[frm.name] = vs[i]
    end
    puts "Calling: #{this.func}: block = #{this.block}"
    eval(f.body, nenv, out, Closure.new(env, this.block))
  end
    
  def Yield(this, env, out, block)
    eval(block.body, block.env, out, nil)
  end


  def Block(this, env, out, block)
    this.stats.each do |stat|
      eval(stat, env, out, block)
    end
  end

  def Text(this, env, out, block)
    out << @coder.encode(this.value)
  end

end

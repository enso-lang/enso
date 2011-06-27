=begin

Inline function for EnsoWeb programs. Removes all calls.

=end

require 'core/batches/code/closure'

class WebInline

  def initialize(web)
    @web = web
    @env = {}
    eval(Loader.load("prelude.web"), @env)
    eval(@web, @env)
  end

  def self.inline(web)
    w = WebInline.new(Clone(web))
    web.toplevels.each do |d|
      if d.schema_class.name=="Def"
        d.body = w.inline_def(d.name)
      end
    end
    web
  end

  def inline_def(def_name)
    @env[def_name].run(@env, nil)
  end

  def eval(obj, *args)
    send(obj.schema_class.name, obj, *args)
  end

  def Web(this, env)
    this.toplevels.each do |t|
      eval(t, env)
    end
  end

  def Def(this, env)
    if env[this.name] then
      puts "Duplicate definition #{this.name}; overwriting."
    end
    env[this.name] = Function.new(self, env, this)
  end

  def method_missing(fun_name, *args)
    if fun_name.to_s.start_with?("exp_")
      return args[0]
    else
      raise "Unknown method #{fun_name.to_s}"
    end
  end

  def Element(this, env, out)
    oldattrs = this.attrs.values + []
    this.attrs.clear
    oldattrs.each do |attr|
      this.attrs << eval_exp(attr.exp, env)
    end

    oldbody = this.body+[]
    this.body.clear
    oldbody.each do |stat|
      this.body << eval(stat, env, out)
    end

    this
  end

  def Output(this, env, out)
    this.exp = Copy(this.factory, eval_exp(this.exp, env))
    this
  end

  def For(this, env, out)
    this.iter = eval_exp(this.iter, env)
    this.body = eval(this.body, env, out)
    #r = eval_exp(this.iter, env)
=begin
    nenv = {}.update(env)
    coll = r.value
    coll.each_with_index do |v, i|
      if coll.is_a?(Array) # literal list expression
        # or list resulting from cons calls
        # NB: the list contains Result objects.
        nenv[this.var] = Result.new(v.value, v.path)
      else
        key_field = ClassKey(v.schema_class)
        key = key_field ? v[key_field.name] : i
        nenv[this.var] = Result.new(v, r.path + "[#{key}]")
      end
      nenv[this.index] = Result.new(i) if this.index
      eval(this.body, nenv, out)
    end
=end
    this
  end

  def If(this, env, out)
    this.cond = Copy(this.factory, eval_exp(this.cond, env))
    this.body = eval(this.body, env, out) unless this.body.nil?
    this.else = eval(this.else, env, out) unless this.else.nil?
    this
  end

  def Let(this, env, out)
    this.decls.each do |assign|
      assign.exp = eval_exp(assign.exp, env)
    end
    this.body = eval(this.body, env, out)
    this
  end

  def Call(this, env, out)
    puts "Calling:"
    Print.print(this)
    func = eval_exp(this.exp, env)
    if !func then
      tag(func.name, {}, out) do
        eval(this.block, env, out) if this.block
      end
    else
      func.apply(this.args, this.block, env, out)
    end
    puts "End Call"
  end

  def Block(this, env, out)
    nstats = this.stats.values + []
    this.stats.clear
    nstats.each do |stat|
      this.stats << eval(stat, env, out)
    end
    this
  end

  def Text(this, env, out)
    this
  end

  def eval_exp(obj, *args)
    send("exp_"+obj.schema_class.name, obj, *args)
  end

  def exp_Var(this, env)
    #log.debug("VAR: #{this.name}")
    if env[this.name] then
      env[this.name] # env binds results
    #elsif this.name == 'root'
    #  Result.new(@root, '')
    else
      #assume this name is not bound
      this
    end
  end

  def exp_Concat(this, env)
    this.lhs = eval_exp(this.lhs, env)
    this.rhs = eval_exp(this.rhs, env)
    this
  end

  def exp_Equal(this, env)
    this.lhs = eval_exp(this.lhs, env)
    this.rhs = eval_exp(this.rhs, env)
    this
  end

end

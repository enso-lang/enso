

require 'core/system/library/schema'
require 'core/system/load/load'
require 'core/web/code/eval_exp'
require 'core/web/code/closure'
require 'core/web/code/utils'

class EvalWeb
  attr_reader :log
  
  PRELUDE_NAME = 'prelude'
  PRELUDE = Loader.load("#{PRELUDE_NAME}.web")
  
  def initialize(web, root, actions, log)
    @web = web
    @root = root
    @actions = actions
    @imports = {}
    @log = log
    @eval_exp = EvalExp.new(root, @actions, @log)
    @env = {}
    @imports[PRELUDE_NAME] = PRELUDE
    eval(PRELUDE, @env)
    eval(web, @env)
  end

  def eval(obj, *args)
    send(obj.schema_class.name, obj, *args)
  end

  def eval_exp(exp, env)
    @eval_exp.eval(exp, env)
  end

  def Web(this, env)
    this.toplevels.each do |t|
      eval(t, env)
    end
  end

  def Def(this, env)
    if env[this.name] then
      log.warn("Duplicate definition #{this.name}; overwriting.")
    end
    env[this.name] = Result.new(Function.new(self, env, this))
  end

  def Import(this, env)
    mod = this.module
    unless @imports[mod]
      web = Loader.load("#{mod}.web")
      @imports[mod] = web
      eval(web, env)
    end
  end
    

  def Element(this, env, out)
    attrs = {}
    this.attrs.each do |attr|
      attrs[attr.name] = eval_exp(attr.exp, env)
    end
    tag(this.tag, attrs, out) do
      this.body.each do |stat|
        eval(stat, env, out)
      end
    end
  end

  def Output(this, env, out)
    result = eval_exp(this.exp, env)
    result.render(out)
  end

  def For(this, env, out) 
    r = eval_exp(this.iter, env)
    nenv = {}.update(env)
    coll = r.value
    coll.each_with_index do |v, i|
      if coll.is_a?(Array) # literal list expression
        # or list resulting from cons calls
        # NB: the list contains Result objects.
        nenv[this.var] = Result.new(v.value, v.path)
      else
        # TODO: add each_with_index to ManyField
        key_field = ClassKey(v.schema_class)
        key = key_field ? v[key_field.name] : i
        nenv[this.var] = Result.new(v, r.path + "[#{key}]")
      end
      nenv[this.index] = Result.new(i) if this.index
      eval(this.body, nenv, out)
    end
  end

  def Do(this, env, out)
    action = eval_exp(this.call)
    cond = this.cond && eval_exp(this.cond)
    action.render(out, cond)
  end

  def If(this, env, out)
    r = eval_exp(this.cond, env)
    if r.value then
      eval(this.body, env, out)
    elsif this.else then
      eval(this.else, env, out)
    end
  end

  def Let(this, env, out)
    nenv = {}.update(env)
    this.decls.each do |assign|
      log.debug "Evaling assignment to: #{assign.name}"
      # NB: use nenv, so basically let is let*
      nenv[assign.name] = eval_exp(assign.exp, nenv)
    end
    eval(this.body, nenv, out)
  end

  def Call(this, env, out)
    func = eval_exp(this.exp, env).value
    if func then
      func.apply(this.args, this.block, env, out)
    else
      log.warn("Undefined template function: #{this.name}")
    end
  end

  def Block(this, env, out)
    this.stats.each do |stat|
      eval(stat, env, out)
    end
  end

  def Text(this, env, out)
    out << @coder.encode(this.value)
  end

end

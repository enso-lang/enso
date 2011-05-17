
require 'htmlentities'
require 'uri'

require 'core/system/library/schema'
require 'core/web/code/eval_exp'
require 'core/web/code/utils'

class EvalWeb
  include WebUtils
  
  def initialize(web, root)
    @web = web
    @root = root
    @tenv = {}
    web.defs.each do |f|
      @tenv[f.name] = f
    end
    #puts @tenv
    @coder = HTMLEntities.new
    @eval_exp = EvalExp.new(root)
  end


  def defines?(name)
    @tenv[name]
  end
  
  def eval_req(name, params, out)
    env = {}
    params.each do |k, v|
      env[k] = Result.new(v)
    end
    eval(@tenv[name].body, env, out, nil)
  end

  def handle_submit(params, out)
    params.each do |k, v|
      puts "VAR: #{k}: #{v}"
    end

    key = params.keys.find do |name|
      # todo factor this sigil out and reuse it also with gensym
      name =~ /^\$\$/
    end
    url = params["redirect_#{key}"]

    # update the assignments    
    params.each do |k, v|
      update(@root, k, v)
    end

    return url
  end


  def eval(obj, *args)
    send(obj.schema_class.name, obj, *args)
  end

  def Element(this, env, out, block)
    out << "<#{this.tag}"
    this.attrs.each do |attr|
      out << ' ' 
      r = @eval_exp.eval(attr.exp, @tenv, env)
      val = @coder.encode(r.value)
      out << "#{attr.name}=\"#{val}\""
    end
    out << ">"
    this.body.each do |stat|
      eval(stat, env, out, block)
    end
    out << "</#{this.tag}>"
  end

  def Output(this, env, out, block)
    r = @eval_exp.eval(this.exp, @tenv, env)
    out << @coder.encode(r.value)
  end

  def For(this, env, out, block) 
    r = @eval_exp.eval(this.iter, @tenv, env)
    nenv = {}.update(env)
    coll = r.value
    coll.each_with_index do |v, i|
      if coll.is_a?(Array) # literal list expression
        # NB: the list contains results.
        nenv[this.var] = Result.new(v.value, v.path)
      else
        key_field = ClassKey(v.schema_class)
        key = key_field ? v[key_field.name] : i
        nenv[this.var] = Result.new(v, r.path + "[#{key}]")
      end
      nenv[this.index] = Result.new(i) if this.index
      eval(this.body, nenv, out, block)
    end
  end

  def If(this, env, out, block)
    r = @eval_exp.eval(this.cond, @tenv, env)
    if r.value then
      eval(this.body, env, out, block)
    elsif this.else then
      eval(this.else, env, out, block)
    end
  end

  def Let(this, env, out, block)
    nenv = {}.update(env)
    this.decls.each do |assign|
      nenv[assign.name] = @eval_exp.eval(assign.exp, @tenv, env)
    end
    eval(this.body, nenv, out, block)
  end

  def Call(this, env, out, block)
    f = @tenv[this.func]
    vs = this.args.map do |exp|
      #puts "Evaluating #{exp}"
      r = @eval_exp.eval(exp, @tenv, env)
      #puts "REsult = #{r}"
      r
    end
    nenv = {}.update(env)
    f.formals.each_with_index do |frm, i|
      nenv[frm.name] = vs[i]
    end
    #puts "Calling: #{this.func}: block = #{this.block}"
    block = Closure.new(env, this.block) if this.block
    eval(f.body, nenv, out, block)
  end
    
  def Yield(this, env, out, closure)
    return unless closure
    vs = this.args.map do |exp|
      @eval_exp.eval(exp, @tenv, env)
    end
    nenv = {}.update(closure.env)
    closure.block.formals.each_with_index do |frm, i|
      nenv[frm.name] = vs[i]
    end
    if closure.block.formals.empty? then
      nenv['it'] = vs[0]
    end
    closure.block.stats.each do |stat|
      eval(stat, nenv, out, nil)
    end
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

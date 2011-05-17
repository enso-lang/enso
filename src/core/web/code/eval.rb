
require 'htmlentities'
require 'uri'
require 'core/system/library/schema'

class EvalWeb

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
    end

    def eval(obj, *args)
      send(obj.schema_class.name, obj, *args)
    end
    
    def Link(this, tenv, env)
      r = eval(this.exp, tenv, env)
      func, *args = r.value

      params = []      
      func.formals.each_with_index do |frm, i|
        params << "#{frm.name}=#{URI.escape(args[i].value)}"
      end

      return Result.new(func.name) if params.empty?
      return Result.new("#{func.name}?#{params.join('&')}")
    end
      

    def Str(this, tenv, env)
      Result.new(this.value)
    end

    def Var(this, tenv, env)
      #puts "ENV = #{env}"
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

    def Address(this, tenv, env)
      r = eval(this.exp, tenv, env)
      return Result.new(r.path)
    end

    def Field(this, tenv, env)
      r = eval(this.exp, tenv, env)
      #puts "---------------> Field: #{r} #{this.name}"
      return Result.new(r.value[this.name], "#{r.path}.#{this.name}")
    end

    def Call(this, tenv, env)
      vs = this.args.map do |arg|
        eval(arg, tenv, env)
      end
      Result.new([tenv[this.func], *vs])
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
    #puts @tenv
    @coder = HTMLEntities.new
    @exp_eval = EvalExp.new(root)
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
  

  private

  def update(obj, k, v)
    if k =~ /^\.(.*)/ then
      field = $1
    else
      return
    end

    puts "Updating: #{field} in #{obj} to #{v}"

    if v.is_a?(Hash) then
      update_collection(obj[field], v)
    else
      puts "Setting obj[#{field}] to #{v}"
      obj[field] = v
    end
  end

  def update_collection(coll, hash)
    # keys are keys in coll
    puts "Updating collection: #{coll} to #{hash}"
    hash.each do |k, v|
      if k =~ /^[0-9]+/ then
        key = Integer($&)
      elsif k =~ /^[a-zA-Z_][a-zA-Z0-9_]*$/ then
        # NB: make sure this never matches $$ stuff.
        # this regexp should match exactly with sym in scanner
        key = $&
      else
        raise "Invalid collection key: #{k}"
      end
      v.each do |k, v|
        # delete and and, otherwise hashing messes up
        x = update(coll[key], k, v)
        puts "COLL: #{coll}"
        coll.delete(coll[key])
        puts "AFTER DELETE: #{coll}"
        coll << x
        puts "AFTER ADD: #{coll}"
      end
    end
  end


  def eval(obj, *args)
    send(obj.schema_class.name, obj, *args)
  end

  def Element(this, env, out, block)
    out << "<#{this.tag}"
    this.attrs.each do |attr|
      out << ' ' 
      r = @exp_eval.eval(attr.exp, @tenv, env)
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
    r = @exp_eval.eval(this.exp, @tenv, env)
    out << @coder.encode(r.value)
  end

  def For(this, env, out, block) 
    r = @exp_eval.eval(this.iter, @tenv, env)
    nenv = {}.update(env)
    r.value.each_with_index do |v, i|
      key_field = ClassKey(v.schema_class)
      if key_field then
        key = v[key_field.name]
      else
        key = i
      end
      nenv[this.var] = Result.new(v, r.path + "[#{key}]")
      nenv[this.index] = Result.new(i) if this.index
      eval(this.body, nenv, out, block)
    end
  end

  def If(this, env, out, block)
    r = @exp_eval.eval(this.cond, @tenv, env)
    if r.value then
      eval(this.body, env, out, block)
    elsif this.else then
      eval(this.else, env, out, block)
    end
  end

  def Let(this, env, out, block)
    nenv = {}.update(env)
    this.decls.each do |assign|
      nenv[assign.name] = @exp_eval.eval(assign.exp, @tenv, env)
    end
    eval(this.body, nenv, out, block)
  end

  def Call(this, env, out, block)
    f = @tenv[this.func]
    vs = this.args.map do |exp|
      #puts "Evaluating #{exp}"
      r = @exp_eval.eval(exp, @tenv, env)
      #puts "REsult = #{r}"
      r
    end
    nenv = {}.update(env)
    f.formals.each_with_index do |frm, i|
      nenv[frm.name] = vs[i]
    end
    #puts "Calling: #{this.func}: block = #{this.block}"
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

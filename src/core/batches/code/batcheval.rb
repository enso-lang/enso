=begin

Transforms a web query to a batch version

This class is a substitute for Render.rb from EnsoWeb, which, instead of evaluating a webpage to an output, produces a query object instead

=end

require 'core/web/code/closure'
require 'core/security/code/bind'
require 'core/web/code/renderable'
require 'core/web/code/render'

require 'logger'

class BatchEval < Web::Eval::Render

  class Expr
    extend ExprBind
  end

  def self.batch(web, rootschema)
    schema = rootschema.schema
    factory = Factory.new(Loader.load('batch.schema'))
    res = {}
    env = {}
    prelude = Loader.load("prelude.web")
    prelude.toplevels.each do |top|
      if top.Def?
        env[top.name] = Web::Eval::Result.new(Web::Eval::Function.new(env, top))
      end
    end
    web.toplevels.each do |t|
      if t.schema_class.name == "Def"
        root_query = factory.Query(rootschema.name)
        BatchEval.new(schema, factory).eval(t.body, env.merge({'root' => root_query}), nil, nil)
        res[t.name] = root_query
      end
    end
    return res
  end

  def initialize(schema, factory)
    @schema = schema
    @factory = factory
    @filter = @factory.EBoolConst(true)
    super(nil, Logger.new($stderr))
  end

  def eval(obj, *args)
    send(obj.schema_class.name, obj, *args)
  end

  def eval_exp(exp, env, errors)
    send("exp_"+exp.schema_class.name, exp, env, errors)
  end

  def save_filter(newfilter=@filter)
    oldfilter = @filter
    @filter = newfilter
    res = yield
    @filter = oldfilter
    res
  end

  def For(this, env, out, errors)
    q = eval_exp(this.iter, env, errors)
    if q.is_a?(CheckedObject) and q.Query?
      nenv = {}.update(env)
      nenv[this.var] = q
      save_filter(@factory.EBoolConst(true)) {
        eval(this.body, nenv, out, errors)
      }
    else
      super(this, env, out, errors)
    end
  end

  def If(this, env, out, errors)
    cond = make_exp(this.cond, env)
    filt = @filter.nil? ? cond : @factory.EBinOp('and', @filter, cond)
    save_filter(filt) {
      eval(this.body, env, out, errors)
    }
    if !this.else.nil?
      not_cond = @factory.EUnOp('not', cond)
      filt2 = @filter.nil? ? not_cond : @factory.EBinOp('and', @filter, not_cond)
      save_filter(filt2) {
        eval(this.else, env, out, errors)
      }
    end
  end

  def tag(name, attrs, out)
    #do nothing just yield
    yield
  end

  def Output(this, env, out, errors)
    result = eval_exp(this.exp, env, errors)
    #result.render(out)
  end

  def Text(this, env, out, errors)
    #Text.new(this.value).render(out)
  end

  def Do(this, env, out, errors)
    if this.cond.nil?
      filt = @filter
    else
      cond = make_exp(this.cond, env)
      filt = @filter.nil? ? cond : @factory.EBinOp('and', @filter, cond)
    end
    save_filter(filt) {
      action = eval_exp(this.call, env, errors)
    }
  end

  #########################
  # Eval expressions
  #########################

  def exp_Field(this, env, errors)
    inner = eval_exp(this.exp, env, errors)
    if inner.is_a?(CheckedObject) and inner.Query?
      fname = this.name
      existing_f = inner.fields.detect{|f| f.name == fname}
      if !existing_f.nil?
        q = existing_f.query
      else
        schema_class = @schema.types[inner.classname]
        tgt_class = schema_class.all_fields[fname].type
        q = tgt_class.Primitive? ? nil : @factory.Query(tgt_class.name)
        f = @factory.Field(fname, q)
        inner.fields << f
      end
      return q
    else
      return Web::Eval::Result.new(inner.value[this.name], inner.path && inner.path.descend_field(this.name))
    end
  end

  def exp_Var(this, env, errors)
    q = env[this.name]
    if q.is_a?(CheckedObject) and q.Query?
      if !q.filter.nil?
        q.filter = Expr.bind!(@factory.EBinOp("or", q.filter, Clone(@filter)), {this.name => @factory.EVar("@self")})
      else
        q.filter = Expr.bind!(Clone(@filter), {this.name => @factory.EVar("@self")})
      end
    end
    return q
  end

  def exp_Call(this, env, errors)
    args = this.args.map do |arg|
      eval_exp(arg, env, errors)
    end
  end

  def exp_Str(this, env, errors)
    Web::Eval::Result.new(this.value)
  end

  def exp_Int(this, env, errors)
    Web::Eval::Result.new(this.value)
  end

  def exp_Concat(this, env, errors)
    lhs = eval_exp(this.lhs, env, errors)
    rhs = eval_exp(this.rhs, env, errors)
    if lhs.is_a?Web::Eval::Result and rhs.is_a?Web::Eval::Result
      Web::Eval::Result.new(lhs.value + rhs.value)
    else
      Web::Eval::Result.new(nil)
    end
  end

  def exp_Equal(this, env, errors)
    lhs = eval_exp(this.lhs, env, errors)
    rhs = eval_exp(this.rhs, env, errors)
    if lhs.is_a?Web::Eval::Result and rhs.is_a?Web::Eval::Result
      Web::Eval::Result.new(lhs.value == rhs.value)
    else
      Web::Eval::Result.new(nil)
    end  end

  def exp_In(this, env, errors)
    lhs = eval_exp(this.lhs, env, errors)
    rhs = eval_exp(this.rhs, env, errors)
    if lhs.is_a?Web::Eval::Result and rhs.is_a?Web::Eval::Result
      rhs.value.each do |x|
        if lhs.value == x then
          return Result.new(true)
        end
      end
      Web::Eval::Result.new(false)
    else
      Web::Eval::Result.new(nil)
    end
  end

  def exp_Address(this, env, errors)
    path = eval_exp(this.exp, env, errors)
    if path.is_a?Web::Eval::Result
      path = eval(this.exp, env, errors).path
      @log.warn("Address asked, but path is nil (val = #{path})") if path.nil?
      Web::Eval::Result.new(path)
    else
      Web::Eval::Result.new(nil)
    end
  end

  def exp_New(this, env, errors)
    Web::Eval::Result.new(nil)
  end

  def exp_Subscript(this, env, errors)
    obj = eval_exp(this.obj, env, errors)
    sub = eval_exp(this.exp, env, errors)
    if obj.is_a?Web::Eval::Result and sub.is_a?Web::Eval::Result
      Web::Eval::Result.new(obj.value[sub.value], sub.path &&
                 sub.path.descend_collection(sub.value))
    else
      Web::Eval::Result.new(nil)
    end
  end

  def exp_List(this, env, errors)
    this.elements.map do |elt|
      eval_exp(elt, env, errors)
    end
  end


  #########################
  # Batching expressions
  #########################

  # env is the environment to use for function arguments

  def make_exp(exp, env)
    if self.methods.any?{|m| m.inspect == ":make_exp_#{exp.schema_class.name}"}
      send("make_exp_#{exp.schema_class.name}", exp, env)
    else
      send("make_exp_DEFAULT", exp, env)
    end
  end

  def make_exp_Field(exp, env)
    @factory.EField(make_exp(exp.exp,env), exp.name)
  end

  def make_exp_Var(exp, env)
    @factory.EVar(exp.name)
  end

  def make_exp_Equal(exp, env)
    @factory.EBinOp('==', make_exp(exp.lhs,env), make_exp(exp.rhs,env))
  end

  def make_exp_Concat(exp, env)
    @factory.EBinOp('+', make_exp(exp.lhs,env), make_exp(exp.rhs,env))
  end

  def make_exp_Str(exp, env)
    @factory.EStrConst(exp.value)
  end

  def make_exp_Int(exp, env)
    @factory.EIntConst(exp.value)
  end

  def make_exp_DEFAULT(exp, env)
    @factory.EBoolConst(true)
  end

end

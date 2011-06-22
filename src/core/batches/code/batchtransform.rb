=begin

Transforms a web query to a batch version

=end

require 'core/schema/tools/union'
require 'core/web/code/closure'
require 'core/security/code/bind'
require 'core/batches/code/webinline'

class BatchTransform

  include ExprBind

  def initialize
    @factory = Factory.new(Loader.load('batch.schema'))
  end

  # main function to extract batch scripts from web documents
  def self.batch_web(web, rootschema)
    BatchTransform.new.batch_Web(WebInline.inline(web), rootschema)
  end

  # web is the .web EnsoWeb obj to be processed
  # rootschema is the schema_class of the root object. note that it is NEITHER the root object NOR the entire schema
  def batch_Web(web, rootschema)
    @schema = rootschema.schema
    res = {}
    web.toplevels.each do |t|
      if t.schema_class.name == "Def"
        root_query = @factory.Query(rootschema.name)
        batch(t.body, @factory.EBoolConst(true), {'root' => root_query})
        res[t.name] = root_query
      end
    end
    return res
  end


  #############################################################################
  #start of private section
  private
  #############################################################################

  #########################
  # Batching control
  #########################

  # web = current EnsoWeb element
  # filters = set of filters currently active (based on if stmts from root to here)
  # qmap = map from var_name:str => query_obj
  # smap = map from query_obj => schema_class

  def batch(web, filter, qmap)
    send("batch_#{web.schema_class.name}", web, filter, qmap)
  end

  def batch_For(web, filters, qmap)
    #the iter should be some kind of field access of the current
    raise "For stats are only allowed to iterate over field expressions" if web.iter.schema_class.name!="Field"
    q = batch(web.iter, filters, qmap)
    batch(web.body, @factory.EBoolConst(true), qmap.merge({web.var=>q}))
    return q
  end

  def batch_If(web, filters, qmap)
    #create a condition
    cond = make_exp(web.cond, {})
    filt = filters.nil? ? cond : @factory.EBinOp('and', filters, cond)
    batch(web.body, filt, qmap)
    if !web.else.nil?
      not_cond = @factory.EUnOp('not', cond)
      filt2 = filters.nil? ? not_cond : @factory.EBinOp('and', filters, not_cond)
      batch(web.else, filt2, qmap)
    end
  end

  def batch_Switch(web)
    #!exp: Exp
    #!cases: Case*
    #!default: Stat?
  end

  def batch_Case(web)
    #!name: str
    #!body: Stat
  end

  def batch_Block(web, filters, qmap)
    #!stats: Stat*
    web.stats.each do |s|
      batch(s, filters, qmap)
    end
  end

  def batch_Field(web, filters, qmap)
    inner = batch(web.exp, filters, qmap)
    schema_class = @schema.types[inner.classname]
    fname = web.name
    tgt_class = schema_class.all_fields[fname].type
    q = tgt_class.Primitive? ? nil : @factory.Query(tgt_class.name)
    f = @factory.Field(fname, q)
    inner.fields << f
    return q
  end

  def batch_Var(web, filters, qmap)
    q = qmap[web.name]
    env = {web.name => @factory.EVar("@self")}
    if !q.filter.nil?
      q.filter = bind!(@factory.EBinOp("or", q.filter, Clone(filters)), env)
    else
      q.filter = bind!(Clone(filters), env)
    end
    return q
  end

  def batch_Output(web, filters, qmap)
    return batch(web.exp, filters, qmap)
  end

  def method_missing(class_name, *args)
    if (class_name.to_s.start_with?("batch_"))
      #do nothing for batch_* that are not defined
    else
      #raise error to ensure that genuine method missing errors are discovered
      raise "Function #{class_name} not found in #{self}!"
    end
  end

  #########################
  # Batching expressions
  #########################

  # env is the environment to use for function arguments

  def make_exp(exp, env)
    send("make_exp_#{exp.schema_class.name}", exp, env)
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

end


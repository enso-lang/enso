=begin

Converts an Enso expression into a batch script expression

=end

include Java

$CLASSPATH<<'../../batches/jaba/target/test-classes'

require "core/system/library/schema"
require "core/batches/code/utils"

require "../../batches/runtime/target/runtime-1.0-SNAPSHOT.jar"

module Jaba
include_class Java::batch.Op
include_class Java::batch.sql.syntax.Factory
end

class Query2Batch

  def self.query2batch(query, schema)
    Query2Batch.new(schema).query2batch(query)
  end

  def initialize(schema)
    @schema = schema  # NOTE: factory is NOT a factory for this schema!!!!
    @factory = Jaba::Factory.factory
    @opmap = {
      "+"  => Jaba::Op::ADD,
      "-"  => Jaba::Op::SUB,
      "*"  => Jaba::Op::MUL,
      "/"  => Jaba::Op::DIV,
      "%"  => Jaba::Op::MOD,
      "&&" => Jaba::Op::AND,
      "and"=> Jaba::Op::AND,
      "||" => Jaba::Op::OR,
      "or" => Jaba::Op::OR,
      "!"  => Jaba::Op::NOT,
      "not"=> Jaba::Op::NOT,
      "==" => Jaba::Op::EQ,
      "!=" => Jaba::Op::NE,
      "<"  => Jaba::Op::LT,
      ">"  => Jaba::Op::GT,
      "<=" => Jaba::Op::LE,
      ">=" => Jaba::Op::GE
    }
  end

  def query2batch(query)
    fname = query.classname
    env1 = {fname => @factory.Var(fname)}
    @factory.Loop(Jaba::Op::SEQ, fname,
                  @factory.Prop(@factory.Root(), tablename_from_name(@schema.root_class, query.classname)),
                  e2b_Query(query, fname, env1))
  end

  def wrap(classname)
    oldclassname = @classname
    @classname = classname
    res = yield
    @classname = oldclassname
    res
  end

  def e2b_Query(query, pname, env)
    keyfield = ClassKey(@schema.classes[query.classname])
    if query.fields.none? {|f| f.name == keyfield.name}
      query.fields << query.factory.Field(keyfield.name)
    end
    body = @factory.Prim(Jaba::Op::SEQ, query.fields.map{|f|e2b_Field(f, pname, env)})
    body = @factory.If(e2b(query.filter), body, @factory.Prim(Jaba::Op::SEQ, [])) if !query.filter.nil?
    body
  end

  def e2b_Field(field, pname, env)
    fname = pname+"_"+field.name
    if field.query.nil?
      res = @factory.Out(fname, @factory.Prop(env[pname], field.name))
    else
      multi = @schema.classes[field.owner.classname].fields[field.name].many
      if multi
        env1 = env.merge({fname => @factory.Var(fname)})
        res = @factory.Loop(Jaba::Op::SEQ, fname, @factory.Prop(env[pname], field.name), e2b_Query(field.query, fname, env1))
      else
        env1 = env.merge({fname => @factory.Prop(env[pname], field.name)})
        res = e2b_Query(field.query, fname, env1)
      end
    end
  end

  def e2b_ComputedField(field, pname)
    @factory.Out(pname+"_"+field.name, e2b(field.expr))
  end

  def e2b(this, *args)
    send("e2b_#{this.schema_class.name}", this, *args)
  end

  def e2b_EBinOp(expr)
    args = [e2b(expr.e1), e2b(expr.e2)]
    @factory.Prim(@opmap[expr.op], args)
  end

  def e2b_EUnOp(expr)
    args = [e2b(expr.e1)]
    @factory.Prim(@opmap[expr.op], args)
  end

  def e2b_EField(expr)
    @factory.Prop(e2b(expr.e), expr.fname)
  end

  def e2b_EVar(expr)
    if expr.name == "@self"
      @factory.Var(@classname)
    else
      @factory.Var(expr.name)
    end
  end

  def e2b_EListComp(expr)
    if expr.op == "all?"
      op = Jaba::Op::AND
    elsif expr.op == "any?"
      op = Jaba::Op::OR
    end
    @factory.Loop(op, expr.var, e2b(expr.list), e2b(expr.expr))
  end

  def e2b_EStrConst(expr)
    @factory.Data(expr.val)
  end

  def e2b_EIntConst(expr)
    @factory.Data(expr.val)
  end

  def e2b_EBoolConst(expr)
    @factory.Data(expr.val)
  end

end
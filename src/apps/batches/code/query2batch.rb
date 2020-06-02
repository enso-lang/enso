=begin

Converts an Enso expression into a batch script expression

=end

include Java

$CLASSPATH<<'lib/runtime-1.0-SNAPSHOT.jar'

require "core/system/library/schema"
require "apps/batches/code/utils"

require "lib/runtime-1.0-SNAPSHOT.jar"

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

  def e2b_Query(query, pname, env)
    keyfield = @schema.classes[query.classname].key
    if query.fields.none? {|f| f.name == keyfield.name}
      query.fields << query.factory.Field(keyfield.name)
    end
    env1 = env.merge({"@self" => env[pname]})
    body = @factory.Prim(Jaba::Op::SEQ,
                         query.fields.map {|f| f.is_a?("ComputedField") ? e2b_ComputedField(f, pname, env1) : e2b_Field(f, pname, env1)})
    if !query.filter.nil?
      body = @factory.If(
                e2b(query.filter, env1),
                body,
                @factory.Prim(Jaba::Op::SEQ, []))
    end
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
        @factory.Loop(Jaba::Op::SEQ, fname, @factory.Prop(env[pname], field.name), e2b_Query(field.query, fname, env1))
      else
        env1 = env.merge({fname => @factory.Prop(env[pname], field.name)})
        e2b_Query(field.query, fname, env1)
      end
    end
  end

  def e2b_ComputedField(field, pname, env)
    @factory.Out(pname+"_"+field.name, e2b(field.expr, env))
  end

  def e2b(this, env)
    send("e2b_#{this.schema_class.name}", this, env)
  end

  def e2b_EBinOp(expr, env)
    Print::Print.print(expr)
    args = [e2b(expr.e1, env), e2b(expr.e2, env)]
    @factory.Prim(@opmap[expr.op], args)
  end

  def e2b_EUnOp(expr, env)
    Print::Print.print(expr)
    args = [e2b(expr.e, env)]
    @factory.Prim(@opmap[expr.op], args)
  end

  def e2b_EField(expr, env)
    @factory.Prop(e2b(expr.e, env), expr.fname)
  end

  def e2b_EVar(expr, env)
    puts "e2b var on #{expr.name}, which is #{env[expr.name].nil? ? "NIL" : env[expr.name]}"
    env[expr.name]
  end

  def e2b_EListComp(expr, env)
    if expr.op == "all?"
      op = Jaba::Op::AND
    elsif expr.op == "any?"
      op = Jaba::Op::OR
    end
    @factory.Loop(op, expr.var, e2b(expr.list, env), e2b(expr.expr, env))
  end

  def e2b_EStrConst(expr, env)
    @factory.Data(expr.val)
  end

  def e2b_EIntConst(expr, env)
    @factory.Data(expr.val)
  end

  def e2b_EBoolConst(expr, env)
    @factory.Data(expr.val)
  end

end

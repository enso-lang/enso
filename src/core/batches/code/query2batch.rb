=begin

Converts an Enso expression into a batch script expression

=end

include Java

$CLASSPATH<<'../../batches/jaba/target/test-classes'

require "../../batches/runtime/target/runtime-1.0-SNAPSHOT.jar"

module Jaba
include_class Java::batch.Op
include_class Java::batch.sql.syntax.Factory
end

class Query2Batch

  def self.query2batch(expr)
    Query2Batch.new.e2b(expr, "root", nil)
  end

  def initialize
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

  def e2b(this, *args)
    send("e2b_#{this.schema_class.name}", this, *args)
  end

  def e2b_Query(query, pname, list)
    if list.nil?
      #should only happen at query root
      list = @factory.Prop(@factory.Root(), query.classname)
    end
    body = @factory.Prim(Jaba::Op::SEQ, query.fields.map{|f|e2b(f, pname)})
    cond = query.filter.nil? ? body : @factory.If(e2b(query.filter), body, nil)
    @factory.Loop(Jaba::Op::SEQ, pname, list, cond)
  end

  def e2b_Field(field, pname)
    fname = pname+"_"+field.name
    if field.query.nil?
      @factory.Out(fname, @factory.Prop(@factory.Var(pname), field.name))
    elsif
      list = @factory.Prop(@factory.Var(pname), field.fname)
      e2b(field.query, fname, list)
    end
  end

  def e2b_ComputedField(field)
    @factory.Out(pname+"_"+field.name, e2b(field.expr))
  end

  def e2b_EBinOp(expr)
    args = [e2b(expr.e1), e2b(expr.e2)]
    @factory.Prim(@opmap[expr.op], args)
  end

  def e2b_EUnOp(expr)
    args = [e2b(expr.e1)]
    @factory.Prim(@opmap[expr.op], args)
  end

  def e2b_EField(expr, env)
    @factory.Prop(e2b(expr.e), expr.fname)
  end

  def e2b_EVar(expr, env)
    @factory.Var(expr.name)
  end

  def e2b_EListComp(expr, env)
    if expr.op == "all?"
      op = Jaba::Op::AND
    elsif expr.op == "any?"
      op = Jaba::Op::OR
    end
    @factory.Loop(op, expr.var, e2b(expr.list), e2b(expr.expr))
  end

  def e2b_EStrConst(expr)
    @factory.Constant(expr.val)
  end

  def e2b_EIntConst(expr)
    @factory.Constant(expr.val)
  end

  def e2b_EBoolConst(expr)
    @factory.Constant(expr.val)
  end

end
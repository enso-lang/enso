

class Infer

  # NOTE: this class does not do typechecking of
  # expressions it just extract field types.
  # NOTE: it is far from complete.

  def initialize(schema)
    @schema = schema
  end

  def infer(x, klass)
    if respond_to?(x.schema_class.name) then
      send(x.schema_class.name, x, klass)
    else 
      {}
    end
  end

  def EBinOp(this, klass)
    infer(this.e1, klass).update(infer(this.e2, klass))
  end

  def EVar(this, klass)
    {this.name => klass.fields[this.name].type}
  end

end

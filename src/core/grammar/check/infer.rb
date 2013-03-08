

class Infer

  def infer(x)
    if respond_to?(x.schema_class.name) then
      send(x.schema_class.name, x)
    else 
      {}
    end
  end

  def EBinOp(this)
    # Wrong, but ok...
    if ['+', '-', '*', '/'].include?(this.op) then
      
  end

  def EVar(this, type)
    @fields[this.name] = type
  end

end

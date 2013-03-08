

class DerefSchema

  def initialize(schema, root)
    @schema = schema
    @root = root
  end

  def deref(this, klass)
    if respond_to?(this.schema_class.name)
      send(this.schema_class.name, this, klass)
    else
      nil
    end
  end

  def EVar(this, klass)
    if this.name == 'root' then
      @root
    else
      raise "No variables other that root allowed"
    end
  end

  def EField(this, klass)
    kls = deref(this.e, klass)
    kls.fields[this.fname].type
  end

  def ESubscript(this, klass)
    deref(this.e, klass)
  end
end
    
      

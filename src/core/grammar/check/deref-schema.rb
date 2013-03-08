

class DerefSchema

  def initialize(schema, root)
    @schema = schema
    @root = root
  end

  def deref(this, klass)
    #puts "DEREF: #{this} in #{klass}"
    if respond_to?(this.schema_class.name)
      send(this.schema_class.name, this, klass)
    else
      nil
    end
  end

  def EVar(this, klass)
    if this.name == 'root' then
      @root
    elsif this.name == 'current' then
      klass
    else
      raise "Only 'current' and 'root' are supported"
    end
  end

  def EField(this, klass)
    kls = deref(this.e, klass)
    f = kls.fields[this.fname]
    return f && f.type
  end

  def ESubscript(this, klass)
    deref(this.e, klass)
  end
end
    
      

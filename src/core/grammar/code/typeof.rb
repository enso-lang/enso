
class TypeOf

  def initialize(schema)
    @schema = schema
    @memo = {}
  end

  def typeof(this, klass)
    if respond_to?(this.schema_class.name) then
      send(this.schema_class.name, this, klass)
    else
      []
    end
  end

  def Sequence(this, klass)
    [] 
  end

  def Call(this, klass)
    # NB: it essential we memoize on calls
    # *not* on rules, because we have to 
    # traverse rules multiple times for
    # different call sites
    return [] if @memo[this]
    @memo[this] = true
    typeof(this.rule, klass)
  end

  def Rule(this, klass)
    return [] unless this.arg
    typeof(this.arg, klass)
  end

  def Create(this, klass)
    [@schema.classes[this.name]]
  end

  def Field(this, klass)
    [klass.fields[this.name].type]
  end

  def Alt(this, klass)
    # return a set of types
    this.alts.inject([]) do |cur, alt|
      cur | typeof(alt, klass)
    end
  end

  def Lit(this, klass)
    [@schema.primitives['str']]
  end

  def Ref(this, klass)
    [@schema.classes[this.name]]
  end

  def Value(this, klass)
    # todo: what about atom???
    if this.kind == 'sym' then
      [@schema.primitives['str']]
    else
      [@schema.primitives[this.kind]]
    end
  end

  def Regular(this, klass)
    # just the type, not multiplicity
    typeof(this.arg, klass)
  end

end

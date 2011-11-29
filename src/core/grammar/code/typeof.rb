
class TypeOf

  def initialize(schema)
    @schema = schema
    @memo = {}
  end

  def typeof(this)
    if respond_to?(this.schema_class.name) then
      send(this.schema_class.name, this)
    else
      []
    end
  end

  def Sequence(this)
    # sequences only have types if they are singletons
    if this.elements.length == 1 then
      typeof(this.elements.first)
    else
      []
    end
  end

  def Call(this)
    # NB: it essential we memoize on calls
    # *not* on rules, because we have to 
    # traverse rules multiple times for
    # different call sites
    if @memo[this] then
      @memo[this]
    else
      @memo[this] = typeof(this.rule)
    end
  end

  def Rule(this)
    # TODO return "bottom-type" if arg is nil
    # which should unify with any expected type.
    return [] unless this.arg
    typeof(this.arg)
  end

  def Create(this)
    [@schema.classes[this.name]]
  end

  def Field(this)
    typeof(this.arg)
  end

  def Alt(this)
    # return a set of types
    this.alts.inject([]) do |cur, alt|
      cur | typeof(alt)
    end
  end

  def Lit(this)
    [@schema.primitives['str']]
  end

  def Ref(this)
    [@schema.classes[this.name]]
  end

  def Value(this)
    if this.kind == 'sym' then
      [@schema.primitives['str']]
    else
      [@schema.primitives[this.kind]]
    end
  end

  def Regular(this)
    # just the type, not multiplicity
    typeof(this.arg)
  end

end

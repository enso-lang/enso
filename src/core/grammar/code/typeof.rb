
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
    # the type of sequence is only well-defined if
    # only a single of its elements is typable.
    # So: "a" ([X] X) "b" is OK (because literals get nil as type)
    # but: ([X] X) ([Y] Y) is not OK
    # NB: we ignore any following types such as Y in the latter example.
    this.elements.each do |elt|
      ts = typeof(elt)
      return ts unless ts.empty?
    end
    return []
  end

  def Call(this)
    # NB: it essential we memoize on calls
    # *not* on rules, because we have to 
    # traverse rules multiple times for
    # different call sites
    if @memo[this] then
      @memo[this]
    else
      @memo[this] = []
      @memo[this] |= typeof(this.rule)
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
    if this.arg.Lit? then
      [@schema.primitives['str']]
    else
      typeof(this.arg)
    end
  end

  def Alt(this)
    this.alts.inject([]) do |cur, alt|
      cur | typeof(alt)
    end
  end

  def Lit(this)
    []
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
    typeof(this.arg)
  end

end

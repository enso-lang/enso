

module Symbols


  def with_terminal(x, &block)
    return if eos?(@ci)
    send(x.schema_class.name, x, &block)
  end
    

  def Sequence(this, nxt = nil)
    @cu = create(nxt) if nxt

    item = @gf.Item(this, this.elements, 0)
    return continue(item) unless this.elements.empty?

    # empty
    cr = Leaf.new(@ci)
    @cn = Node.new(item, @cn, cr)
    pop
    continue(nxt)
  end
  
  def Epsilon(this, nxt = nil)
    cr = Leaf.new(@ci)
    @cn = Node.new(@gf.Item(this, [], 0), @cn, cr)
    pop
    continue(nxt)
  end

  def Call(this, nxt = nil)
    recurse(this.rule, nxt)
  end

  def Rule(this, nxt = nil)
    chain(this, nxt)
  end

  def Create(this, nxt = nil)
    chain(this, nxt)
  end

  def Field(this, nxt = nil)
    chain(this, nxt)
  end

  def Alt(this, nxt = nil)
    @cu = create(nxt) if nxt
    this.alts.each do |alt|
      add(alt)
    end
  end

  def Lit(this, nxt = nil)
    with_literal(this.value) do |pos, ws|
      terminal(this, pos, this.value, ws, nxt)
    end
  end

  def Ref(this, nxt = nil)
    with_token('sym') do |pos, tk, ws|
      terminal(this, pos, tk, ws, nxt)
    end
  end

  def Value(this, nxt = nil)
    with_token(this.kind) do |pos, tk, ws|
      terminal(this, pos, tk, ws, nxt)
    end
  end


  def Regular(this, nxt = nil)
    @cu = create(nxt) if nxt
    if !this.many && this.optional then
      add(@gf.Epsilon)
      add(this.arg)
    elsif this.many && !this.optional && !this.sep then
      add(this.arg)
      add(@gf.Item(this, [this.arg, this], 0))
    elsif this.many && this.optional && !this.sep then
      add(@gf.Epsilon)
      add(@gf.Item(this, [this.arg, this], 0))
    elsif this.many && !this.optional && this.sep then
      add(this.arg) # todo
      add(@gf.Item(this, [this.arg, @gf.Lit(this.sep), this], 0))
    elsif this.many && this.optional && this.sep then
      #todo
    end
  end



end

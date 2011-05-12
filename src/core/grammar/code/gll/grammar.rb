

module Symbols

  def with_terminal(x, &block)
    return if eos?(@ci)
    send(x.schema_class.name, x, &block)
  end
    

  def Sequence(this, nxt = nil)
    @cu = create(nxt) if nxt

    item = Item.new(this.elements, 0, this)
    return continue(item) unless this.elements.empty?

    # empty
    cr = Leaf.new(@ci)
    @cn = Node.new(item, @cn, cr)
    pop
    continue(nxt)
  end
  
  def Empty(this, nxt = nil)
    cr = Leaf.new(@ci)
    @cn = Node.new(Item.new([], 0, this), @cn, cr)
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
    puts "// CREATE #{this.name}"
    chain(this, nxt)
  end

  def Field(this, nxt = nil)
    puts "// FIELD #{this.name}"
    chain(this, nxt)
  end

  def Alt(this, nxt = nil)
    @cu = create(nxt) if nxt
    this.alts.each do |alt|
      #puts "Adding in Alt"
      add(alt)
    end
  end

  def Lit(this, nxt = nil)
    with_literal(this.value) do |pos, ws|
      terminal(pos, this.value, ws, nxt)
    end
  end

  def Ref(this, nxt = nil)
    with_token('sym') do |pos, tk, ws|
      terminal(pos, tk, ws, nxt)
    end
  end

  def Value(this, nxt = nil)
    with_token(this.kind) do |pos, tk, ws|
      terminal(pos, tk, ws, nxt)
    end
  end


  def Regular(this, nxt = nil)
    @cu = create(nxt) if nxt
    if !this.many && this.optional then
      add(Empty.new)
      add(this.arg)
    elsif this.many && !this.optional && !this.sep then
      add(this.arg)
      add(Item.new([this.arg, this], 0, this))
    elsif this.many && this.optional && !this.sep then
      add(Empty.new)
      add(Item.new([this.arg, this], 0, this))
    elsif this.many && !this.optional && this.sep then
      add(this.arg) # todo
      add(Item.new([this.arg, @gf.Lit(this.sep), this]))
    elsif this.many && this.optional && this.sep then
      #todo
    end
  end



end

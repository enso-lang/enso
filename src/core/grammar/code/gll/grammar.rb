

module Symbols

  def Item(this)
    if this.dot == this.elements.length then
      pop
    else
      nxt = item(this.expression, this.elements, this.dot + 1)
      recurse(this.elements[this.dot], nxt)
    end
  end

  def Sequence(this, nxt = nil)
    @cu = create(nxt) if nxt

    item = item(this, this.elements, 0)
    return continue(item) unless this.elements.empty?

    # empty
    cr = Empty.new(@ci, @epsilon)
    @cn = Node.new(item, @cn, cr)
    pop
    continue(nxt)
  end
  
  def Epsilon(this, nxt = nil)
    cr = Empty.new(@ci, this)
    @cn = Node.new(item(this, [], 0), @cn, cr)
    pop
    continue(nxt)
  end

  def Code(this, nxt = nil)
    terminal(this, @ci, this.code, '', nxt)
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
    #puts "Parsing literal: #{this.value}"
    with_literal(this.value) do |pos, ws|
      #puts "Success"
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
      add(@epsilon)
      add(this.arg)
    elsif this.many && !this.optional && !this.sep then
      add(this.arg)
      add(item(this, [this.arg, this], 0))
    elsif this.many && this.optional && !this.sep then
      add(@epsilon)
      add(item(this, [this.arg, this], 0))
    elsif this.many && !this.optional && this.sep then
      add(this.arg) # todo
      @seps[this.sep] ||= @gf.Lit(this.sep)
      add(item(this, [this.arg, @seps[this.sep], this], 0))
    elsif this.many && this.optional && this.sep then
      #todo
    end
  end



end



module Symbols

  def terminal?(x)
    %w(Lit Value Ref Empty).include?(x.schema_class.name)
  end

  def with_terminal(x, &block)
    return if eos?(@ci)
    send(x.schema_class.name, x, &block)
  end
    

  def Sequence(this)
    item = Item.new(this, 0)
    if this.elements.empty? then
      cr = Leaf.new(@ci)
      @cn = Node.new(item, @cn, cr)
      pop
    else
      Item(item)
    end
  end

  def Call(this)
    recurse(this.rule)
  end

  def Rule(this)
    recurse(this.arg)
  end

  def Alt(this)
    this.alts.each do |alt|
      #puts "Adding in Alt"
      add(alt)
    end
  end
  
  def Create(this)
    # TODO
    recurse(this.arg)
  end

  def Field(this)
    # TODO
    recurse(this.arg)
  end

  def Regular(this)
    if !this.many && this.optional then
      add(@gf.Empty)
      add(this.arg)
    elsif this.many && !this.optional && !this.sep then
      add(this.arg)
      add(Item.new([this.arg, this]))
    elsif this.many && this.optional && !this.sep then
      add(@gf.Empty)
      add(Item.new([this.arg, this]))
    elsif this.many && !this.optional && this.sep then
      add(this.arg)
      add(Item.new([this.arg, @gf.Lit(this.sep), this]))
    elsif this.many && this.optional && this.sep then
      # ???
    end
  end

  def Value(this)
    with_token(this.kind) do |pos, tk, ws|
      yield Leaf.new(@ci, pos, tk, ws), pos
    end
  end

  def Lit(this)
    with_literal(this.value) do |pos, ws|
      yield Leaf.new(@ci, pos, this.value, ws), pos
    end
  end

  def Ref(this)
    with_token('sym') do |pos, tk, ws|
      yield Leaf.new(@ci, pos, tk, ws), pos
    end
  end


end

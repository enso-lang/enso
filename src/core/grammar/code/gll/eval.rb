require 'core/grammar/code/gll/scan'

class GrammarEval
  attr_reader :start_pos, :start

  def initialize(gll, grammar, source, top)
    @gll = gll
    @scan = Scan.new(grammar, source)
    @ws, @start_pos = @scan.skip_ws
    @fact = grammar._graph_id
    @epsilon = @fact.Epsilon

    @items = {}
    @seps = {}
    @iters = {}

    # NB: depends on @items
    @start = item(top.arg, [top.arg], 1)
  end

  def eval(this, *args)
    send(this.schema_class.name, this, *args)
  end

  def Item(this)
    if this.dot == this.elements.length then
      @gll.pop
    else
      nxt = item(this.expression, this.elements, this.dot + 1)
      eval(this.elements[this.dot], nxt)
    end
  end

  def Sequence(this, nxt = nil)
    item = item(this, this.elements, 0)
    if this.elements.empty? then
      @gll.empty_node(item, @epsilon)
      continue(nxt)
    else
      @gll.create(nxt) if nxt
      continue(item) 
    end
  end
  
  def Epsilon(this, nxt = nil)
    @gll.empty_node(item(this, [], 0), @epsilon)
    continue(nxt)
  end

  def Call(this, nxt = nil)
    eval(this.rule, nxt)
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
    @gll.create(nxt) if nxt
    this.alts.each do |alt|
      @gll.add(alt)
    end
  end

  def Code(this, nxt = nil)
    terminal(this, @gll.ci, this.code, '', nxt)
  end

  def Lit(this, nxt = nil)
    @scan.with_literal(this.value, @gll.ci) do |pos, ws|
      terminal(this, pos, this.value, ws, nxt)
    end
  end

  def Ref(this, nxt = nil)
    @scan.with_token('atom', @gll.ci) do |pos, tk, ws|
      terminal(this, pos, tk, ws, nxt)
    end
  end

  def Value(this, nxt = nil)
    @scan.with_token(this.kind, @gll.ci) do |pos, tk, ws|
      terminal(this, pos, tk, ws, nxt)
    end
  end

  def Regular(this, nxt = nil)
    @gll.create(nxt) if nxt
    if !this.many && this.optional then
      @gll.add(@epsilon)
      @gll.add(this.arg)
    elsif this.many && !this.optional && !this.sep then
      @gll.add(this.arg)
      @gll.add(item(this, [this.arg, this], 0))
    elsif this.many && this.optional && !this.sep then
      @gll.add(@epsilon)
      @gll.add(item(this, [this.arg, this], 0))
    elsif this.many && !this.optional && this.sep then
      @gll.add(this.arg) 
      @seps[this.sep] ||= @fact.Lit(this.sep)
      @gll.add(item(this, [this.arg, @seps[this.sep], this], 0))
    elsif this.many && this.optional && this.sep then
      @iters[this] ||= @fact.Regular(this.arg, false, true, this.sep)
      @gll.add(@epsilon)
      @gll.add(@iters[this])
    else
      raise "Invalid regular: #{this}"
    end
  end


  private

  def chain(this, nxt)
    @gll.create(nxt) if nxt
    @gll.add(item(this, [this.arg], 0))
  end

  def continue(nxt)
    Item(nxt) if nxt
  end


  # TODO: this node stuff does not belong here
  def terminal(type, pos, value, ws, nxt)
    cr = @gll.leaf_node(pos, type, value, ws)
    if nxt then
      @gll.item_node(nxt, cr)
      continue(nxt)
    end
  end

  def item(exp, elts, dot)
    key = [exp, elts, dot]
    @items[key] ||= @fact.Item(exp, elts, dot)
  end

end

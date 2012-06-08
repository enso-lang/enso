require 'core/grammar/parse/scan'

class GrammarEval
  attr_reader :start_pos, :start

  # TODO: use method_missing installing concrete methods
  # based on _id for each grammar thing.

  def initialize(grammar, source, top)
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


  class Item
    attr_reader :expression
    attr_reader :elements
    attr_reader :dot
    
    def initialize(exp, elts, dot)
      @expression = exp
      @elements = elts
      @dot = dot
    end

    def schema_class
      self.class
    end
  end


  def eval(this, gll, nxt)
    if this.is_a?(Item)
      eval_item(this, gll, nxt)
    else
      send(this.schema_class.name, this, gll, nxt)
    end
  end

  def eval_item(this, gll, _)
    if this.dot == this.elements.length then
      gll.pop
    else
      nxt = item(this.expression, this.elements, this.dot + 1)
      eval(this.elements[this.dot], gll, nxt)
    end
  end

  def Sequence(this, gll, nxt)
    item = item(this, this.elements, 0)
    if this.elements.empty? then
      gll.create(nxt) if nxt # this is needed to make sure chaining
      # works correctly in case the leaf is empty; otherwise
      # we lose empty Creates which are needed to make "empty" objects.

      gll.empty_node(item, @epsilon)
      eval_item(nxt, gll, nil) if nxt
    else
      gll.create(nxt) if nxt
      eval_item(item, gll, nil)
    end
  end
  
  def Epsilon(this, gll, nxt)
    empty(this, gll, nxt)
  end

  def NoSpace(this, gll, nxt)
    #terminal(this, gll.ci, '', '', gll, nxt)
    eval_item(nxt, gll, nil) if nxt
  end

  def Break(this, gll, nxt)
    #terminal(this, gll.ci, '', '', gll, nxt)
    eval_item(nxt, gll, nil) if nxt
  end

  def Call(this, gll, nxt)
    eval(this.rule, gll, nxt)
  end

  def Rule(this, gll, nxt)
    chain(this, gll, nxt)
  end

  def Create(this, gll, nxt)
    chain(this, gll, nxt)
  end

  def Field(this, gll, nxt)
    chain(this, gll, nxt)
  end

  def Alt(this, gll, nxt)
    gll.create(nxt) if nxt
    this.alts.each do |alt|
      gll.add(alt)
    end
  end

  def Code(this, gll, nxt)
    terminal(this, gll.ci, this.code, '', gll, nxt)
  end

  def Lit(this, gll, nxt)
    @scan.with_literal(this.value, gll.ci) do |pos, ws|
      terminal(this, pos, this.value, ws, gll, nxt)
    end
  end

  def Ref(this, gll, nxt)
    @scan.with_token('sym', gll.ci) do |pos, tk, ws|
      terminal(this, pos, tk, ws, gll, nxt)
    end
  end

  def Value(this, gll, nxt)
    @scan.with_token(this.kind, gll.ci) do |pos, tk, ws|
      terminal(this, pos, tk, ws, gll, nxt)
    end
  end

  def Regular(this, gll, nxt)
    gll.create(nxt) if nxt
    if !this.many && this.optional then
      gll.add(@epsilon)
      gll.add(this.arg)
    elsif this.many && !this.optional && !this.sep then
      gll.add(this.arg)
      gll.add(item(this, [this.arg, this], 0))
    elsif this.many && this.optional && !this.sep then
      gll.add(@epsilon)
      gll.add(item(this, [this.arg, this], 0))
    elsif this.many && !this.optional && this.sep then
      gll.add(this.arg) 
      gll.add(item(this, [this.arg, this.sep, this], 0))
    elsif this.many && this.optional && this.sep then
      @iters[this] ||= @fact.Regular(this.arg, false, true, this.sep)
      gll.add(@epsilon)
      gll.add(@iters[this])
    else
      raise "Invalid regular: #{this}"
    end
  end


  private

  def chain(this, gll, nxt)
    gll.create(nxt) if nxt
    gll.add(item(this, [this.arg], 0))
  end

  def empty(this, gll, nxt)
    gll.empty_node(item(this, [], 0), @epsilon)
    eval_item(nxt, gll, nil) if nxt
  end

  def terminal(type, pos, value, ws, gll, nxt)
    cr = gll.leaf_node(pos, type, value, ws)
    if nxt then
      gll.item_node(nxt, cr)
      eval_item(nxt, gll, nil)
    end
  end

  def item(exp, elts, dot)
    key = [exp, elts, dot]
    @items[key] ||= Item.new(exp, elts, dot)
  end


end

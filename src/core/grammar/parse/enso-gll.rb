
require 'core/grammar/tools/todot'
require 'core/grammar/parse/sharing-factory'
require 'core/schema/tools/print'
require 'core/schema/tools/copy'
require 'core/grammar/parse/scan'


class EnsoGLL
  attr_reader :ci

  def self.parse(source, grammar, org)
    self.new.parse(source, grammar, org)
  end

  def parse(source, grammar, org)
    @todo = []
    @done = {}
    @toPop = {}

    #puts "PARSING SOURCE:"
    #puts source

    @schema = Load::load('grammar.schema')
    shared = [@schema.classes["Base"],
              @schema.classes["Item"],
              @schema.classes["Edge"],
              @schema.classes["Pack"],
              @schema.classes["GSS"]]

    @fact = SharingFactory::new(@schema, shared)
    @grammar =  Copy.new(@fact).copy(grammar)

    @origins = org

    @scan = Scan.new(@grammar, source)
    @ws, @start_pos = @scan.skip_ws
    @epsilon = @fact.Epsilon

    top = @fact.Item(@grammar.start.arg, [@grammar.start.arg], 1)
    
    @dummy_loc = @fact.Location("", 0, 0, 0, 0, 0, 0)
    @dummy_node = @fact.Leaf(0, 0, @epsilon, @dummy_loc, "$DUMMY$", "")

    @ci = @start_pos
    @cu = @start = @fact.GSS(top, 0)
    @cn = @dummy_node
    puts "CN start = #{@cn}"
    add(@grammar.start.arg)
    dispatch
    result(source, top)
  end

  def dispatch
    while !@todo.empty? do
      parser, @cu, @cn, @ci = @todo.shift
      puts "PARSER = #{parser}"
      puts "CU = #{@cu}"
      puts "CN = #{@cn}"
      puts "CI = #{@ci}"
      eval(parser, nil)
    end
  end

  def eval(this, nxt)
    send(this.schema_class.name, this, nxt)
  end

  def Item(this, _)
    puts "ITEM: #{this}"
    if this.dot == this.elements.size then
      pop
    else
      nxt = @fact.Item(this.expression, this.elements, this.dot + 1)
      eval(this.elements[this.dot], nxt)
    end
  end

  def Sequence(this, nxt)
    item = @fact.Item(this, this.elements, 0)
    if this.elements.empty? then
      create(nxt) if nxt # this is needed to make sure chaining
      # works correctly in case the leaf is empty; otherwise
      # we lose empty Creates which are needed to make "empty" objects.

      empty_node(item, @epsilon)
      Item(nxt, nil) if nxt
    else
      create(nxt) if nxt
      Item(item, nil)
    end
  end
  
  def Epsilon(this, nxt)
    empty(this, nxt)
  end

  def NoSpace(this, nxt)
    Item(nxt, nil) if nxt
  end

  def Indent(this, nxt)
    Item(nxt, nil) if nxt
  end

  def Break(this, nxt)
    Item(nxt, nil) if nxt
  end

  def Call(this, nxt)
    create(nxt) if nxt
    #TODO: arg is always Alt per the grammar
    #but this is not reflected in the schema
    this.rule.arg.alts.each do |alt|
      add(alt)
    end
    #eval(this.rule, nxt)
  end

  # def Rule(this, nxt)
  #   # TODO: this is still there because of
  #   # the start symbol (which is a rule).
  #   chain(this, nxt)
  # end

  def Create(this, nxt)
    chain(this, nxt)
  end

  def Field(this, nxt)
    chain(this, nxt)
  end

  def Alt(this, nxt)
    create(nxt) if nxt
    this.alts.each do |alt|
      add(alt)
    end
  end

  def Code(this, nxt)
    terminal(this, ci, '', '', nxt)
  end

  def Lit(this, nxt)
    @scan.with_literal(this.value, ci) do |pos, ws|
      terminal(this, pos, this.value, ws, nxt)
    end
  end

  def Ref(this, nxt)
    @scan.with_token('sym', ci) do |pos, tk, ws|
      terminal(this, pos, tk, ws, nxt)
    end
  end

  def Value(this, nxt)
    @scan.with_token(this.kind, ci) do |pos, tk, ws|
      terminal(this, pos, tk, ws, nxt)
    end
  end

  def Regular(this, nxt)
    create(nxt) if nxt
    if !this.many && this.optional then
      add(@epsilon)
      add(this.arg)
    elsif this.many && !this.optional && !this.sep then
      add(this.arg)
      add(@fact.Item(this, [this.arg, this], 0))
    elsif this.many && this.optional && !this.sep then
      add(@epsilon)
      add(@fact.Item(this, [this.arg, this], 0))
    elsif this.many && !this.optional && this.sep then
      add(this.arg) 
      add(@fact.Item(this, [this.arg, this.sep, this], 0))
    elsif this.many && this.optional && this.sep then
      # @iters[this] ||= @fact.Regular(this.arg, false, true, this.sep)
      sym = @fact.Regular(this.arg, false, true, this.sep)
      add(@epsilon)
      add(sym)
    else
      raise "Invalid regular: #{this}"
    end
  end


  def chain(this, nxt)
    create(nxt) if nxt
    add(@fact.Item(this, [this.arg], 0))
  end

  def empty(this, nxt)
    empty_node(@fact.Item(this, [], 0), @epsilon)
    Item(nxt, nil) if nxt
  end

  def terminal(type, pos, value, ws, nxt)
    cr = leaf_node(pos, type, value, ws)
    if nxt then
      item_node(nxt, cr)
      Item(nxt, nil)
    end
  end

  def result(source, top)
    r = @fact._objects_for(@schema.classes['Base']).find do |n|
      puts "NODE = #{n}"
      top_node?(n, source, top)
    end
    # if r then 
    #   File.open('sppf.dot', 'w') do |f|
    #     ToDot.to_dot(r, f)
    #   end
    # end
    if r then
      r
    else
    #return r if r
      loc = @origins.str(@ci)
      #Print::Print.print(@cu.item)
      raise "Parse error at #{loc}:\n'#{source[@ci,50]}...'" 
    end
  end
  
  def top_node?(node, source, top)
    node.Node? &&
      node.starts == @start_pos && 
      node.ends == source.size  &&
      node.type == top
  end
  
  def add(parser, u = @cu, i = @ci, w = @dummy_node) 
    if !@done.has_key?(i) then
      @done[i] = {}
    end
    conf = [parser, u, w]
    unless @done[i][conf]
      @done[i][conf] = true
      @todo << [parser, u, w, i]
    end
  end

  def pop
    if @cu.equals(@start) then
      nil
    else
      if !@toPop.has_key?(@cu) then
        @toPop[@cu] = {}
      end
      if !@toPop[@cu].has_key?(@cn) then
        @toPop[@cu][@cn] = @cn
      end
      cnt = @cu.item
      @cu.edges.each do |edge| #|w, gs|
        #gs.each do |u|
        w = edge.sppf
        u = edge.target
        x = make_node(cnt, w, @cn)
        add(cnt, u, @ci, x)
        #end
      end
    end
  end

  def create(item)
    w = @cn
    v = @fact.GSS(item, @ci)
    puts "W = #{w}"
    puts "CU = #{@cu}"
    e = @fact.Edge(w, @cu)
    if !v.edges.include?(e) then
      v.edges << e
      if @toPop[v] then
        @toPop[v].each_key do |z|
          x = make_node(item, w, z)
          add(item, @cu, z.ends, x)
        end
      end
    end
    @cu = v
  end

  def empty_node(item, eps)
    # @dummy_node = @fact.Leaf(0, 0, @epsilon, @dummy_loc, "$DUMMY$", "")

    # change to Empty!!
    cr = @fact.Leaf(@ci, @ci, eps, @dummy_loc, "", "")
    item_node(item, cr)
    pop
  end

  def item_node(item, cr)
    @cn = make_node(item, @cn, cr)
  end

  def leaf_node(pos, type, value, ws)
    # NB: pos includes the ws that has been matched
    # so subtract the size of ws from pos.
    cr = @fact.Leaf(@ci, pos - ws.size, type, @dummy_loc, value, ws)
    @ci = pos
    cr
  end


  def make_node(item, z, w)
    if item.dot == 1 && item.elements.size > 1 then
      return w
    end
    t = item
    if item.dot == item.elements.size then
      t = item.expression
    end
    x = w.type
    k = w.starts
    i = w.ends
    if z != nil then
      s = z.type
      j = z.starts
      # assert k == z.ends
      y = @fact.Node(j, i, t, @dummy_loc)
      y.kids << @fact.Pack(y, item, k, z, w)
    else
      y = @fact.Node(k, i, t, @dummy_loc)
      y.kids << @fact.Pack(y, item, k, nil, w)
    end
    return y
  end
    
  def origin(orgs)
    path = orgs.path
    offset = orgs.offset(starts)
    size = ends - starts
    start_line = orgs.line(starts)
    start_column = orgs.column(starts)
    end_line = orgs.line(ends)
    end_column = orgs.column(ends)
    @fact.Location(path, offset, size, start_line, 
                 start_column, end_line, end_column)
  end

end


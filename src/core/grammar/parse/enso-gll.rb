
require 'core/grammar/tools/todot'
require 'core/grammar/parse/sharing-factory'
require 'core/grammar/parse/gll-factory'
require 'core/schema/tools/print'
require 'core/schema/tools/copy'
require 'core/grammar/parse/scan'
require 'core/system/load/load'
require 'ruby-prof'

module EnsoGLL
  def self.parse(source, grammar, org, start_symbol = grammar.start.name)
    EnsoGLLParser.new(grammar).parse(source, org, start_symbol)
  end

  class FormattingRemover
    
    def remove_formatting(x)
      if is_formatting?(x) then
        $stderr << "WARNING: *not* removing formatting #{x}\n"
      elsif respond_to?(x.schema_class.name)
        send(x.schema_class.name, x)
      end
    end
    
    def Grammar(this)
      this.rules.each do |x|
        remove_formatting(x.arg)
      end
    end
    
    def Sequence(this)
      del = []
      this.elements.each do |x|
        if is_formatting?(x) then
          del << x
        else
          remove_formatting(x)
        end
      end
      del.each do |x|
        this.elements.delete(x)
      end
    end

    def Alt(this)
      this.alts.each do |x|
        remove_formatting(x)
      end
    end

    def Create(this)
      remove_formatting(this.arg)
    end

    def Field(this)
      remove_formatting(this.arg)
    end
    
    def Regular(this)
      remove_formatting(this.arg)
      if this.sep && is_formatting?(this.sep) then
        this.sep = nil
      elsif this.sep then
        remove_formatting(this.sep)
      end
    end

    def is_formatting?(x)
      %w(NoSpace Indent Break).include?(x.schema_class.name)
    end    
  end


  class EnsoGLLParser
    include Interpreter::Dispatcher

    def initialize(grammar, fact = GLLFactory::new)
      @gfact = Factory::new(grammar._graph_id.schema)
      @grammar =  Copy.new(@gfact).copy(grammar)
      FormattingRemover.new.remove_formatting(@grammar)
      @fact = fact
    end

    def parse(source, org, start_symbol)
      @todo = []
      @done = {}
      @toPop = {}
      @iters = {}

      # Important: take the start from copied grammar.
      start_rule = @grammar.rules[start_symbol]


      @origins = org

      @scan = Scan.new(@grammar, source)
      @ws, @start_pos = @scan.skip_ws
      @epsilon = @gfact.Epsilon

      
      @dummy_node = @fact.Leaf(0, 0, @epsilon, 0, "$DUMMY$", "")

      start_item = @fact.Item(start_rule, [start_rule], 1)

      @ci = @start_pos
      @cu = @start = @fact.GSS(start_item, 0)
      @cn = @dummy_node

      add(@fact.Item(start_rule, [start_rule], 0))
      while !@todo.empty? do
        parser, @cu, @cn, @ci = @todo.shift
        eval(parser, nil)
      end
      result(source, start_rule)
    end

    def eval(this, nxt)
      send(this.schema_class.name, this, nxt)
    end

    def Item(this, _)
      if this.dot == this.elements.size then
        pop
      else
        nxt = @fact.Item(this.expression, this.elements, this.dot + 1)
        eval(this.elements[this.dot], nxt)
      end
    end

    def Sequence(this, nxt)
      create(nxt) if nxt
      add(@fact.Item(this, this.elements, 0))
    end
    
    def Epsilon(this, nxt)
      empty_node(@fact.Item(this, [], 0), @epsilon)
      Item(nxt, nil) if nxt
    end

    def Rule(this, nxt)
      create(nxt) if nxt
      this.arg.alts.each do |x|
        add_seq_or_elt(this, x)
      end
    end

    def Call(this, nxt)
      eval(this.rule, nxt)
    end

    def Create(this, nxt)
      create(nxt) if nxt
      add(@fact.Item(this, this.arg.elements, 0))
    end

    def Field(this, nxt)
      create(nxt) if nxt
      add(@fact.Item(this, [this.arg], 0))
    end

    def Alt(this, nxt)
      create(nxt) if nxt
      this.alts.each do |alt|
        add_seq_or_elt(this, alt)
      end
    end

    def Code(this, nxt)
      terminal(this, @ci, '', '', nxt)
    end

    def Lit(this, nxt)
      @scan.with_literal(this.value, @ci) do |pos, ws|
        terminal(this, pos, this.value, ws, nxt)
      end
    end

    def Ref(this, nxt)
      @scan.with_token('sym', @ci) do |pos, tk, ws|
        terminal(this, pos, tk, ws, nxt)
      end
    end

    def Value(this, nxt)
      @scan.with_token(this.kind, @ci) do |pos, tk, ws|
        terminal(this, pos, tk, ws, nxt)
      end
    end

    def Regular(this, nxt)
      create(nxt) if nxt
      if !this.many && this.optional then
        add(@fact.Item(this, [@epsilon], 0))
        add(@fact.Item(this, [this.arg], 0))
      elsif this.many && !this.optional && !this.sep then
        add(@fact.Item(this, [this.arg, this], 0))
        add(@fact.Item(this, [this.arg], 0))
      elsif this.many && this.optional && !this.sep then
        add(@fact.Item(this, [@epsilon], 0))
        add(@fact.Item(this, [this.arg, this], 0))
      elsif this.many && !this.optional && this.sep then
        add(@fact.Item(this, [this.arg], 0)) 
        add(@fact.Item(this, [this.arg, this.sep, this], 0))
      elsif this.many && this.optional && this.sep then
        @iters[this] ||= @gfact.Regular(this.arg, false, true, this.sep)
        add(@fact.Item(this, [@epsilon], 0))
        add(@fact.Item(this, [@iters[this]], 0))
      else
        raise "Invalid regular: #{this}"
      end
    end

    def terminal(type, pos, value, ws, nxt)
      cr = leaf_node(pos, type, value, ws)
      if nxt then
        item_node(nxt, cr)
        Item(nxt, nil)
      end
    end

    def add_seq_or_elt(this, x)
      if x.schema_class.name == 'Sequence' then
        add(@fact.Item(this, x.elements, 0))
      else # Create
        add(@fact.Item(this, [x], 0))
      end
    end

    def result(source, top)
      r = @fact._objects_for(@gfact.schema.classes['Node']).find do |n|
        top_node?(n, source, top)
      end
      if r then
        r
      else
        loc = @origins.str(@ci)
        raise "Parse error at #{loc}:\n'#{source[@ci,50]}...'" 
      end
    end
    
    def top_node?(node, source, top)
      node.starts == @start_pos && 
        node.ends == source.size  &&
        node.type == top
    end
    
    def add(parser, u = @cu, i = @ci, w = @dummy_node) 
      if !@done.has_key?(i) then
        @done[i] = {}
      end
      conf = [parser, u, w]
      if !@done[i][conf]
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
          w = edge.sppf
          u = edge.target
          x = make_node(cnt, w, @cn)
          add(cnt, u, @ci, x)
        end
      end
    end

    def create(item)
      w = @cn
      v = @fact.GSS(item, @ci)
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
      cr = @fact.Empty(@ci, @ci, eps, nil)
      item_node(item, cr)
      pop
    end

    def item_node(item, cr)
      @cn = make_node(item, @cn, cr)
    end

    def leaf_node(pos, type, value, ws)
      # NB: pos includes the ws that has been matched
      # so subtract the size of ws from pos.
      cr = @fact.Leaf(@ci, pos - ws.size, type, origin(@ci, pos - ws.size), value, ws)
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
      if z != @dummy_node then
        s = z.type
        j = z.starts
        # assert k == z.ends
        y = @fact.Node(j, i, t, origin(j, i))
        pack = @fact.Pack(y, item, k, z, w)
        if !y.kids.include?(pack)
          y.kids << pack
        end
      else
        y = @fact.Node(k, i, t, origin(k, i))
        pack = @fact.Pack(y, item, k, nil, w)
        if !y.kids.include?(pack)
          y.kids << pack
        end
      end
      return y
    end
    
    def origin(starts, ends)
      return nil
      path = @origins.path
      offset = @origins.offset(starts)
      size = ends - starts
      start_line = @origins.line(starts)
      start_column = @origins.column(starts)
      end_line = @origins.line(ends)
      end_column = @origins.column(ends)
      @fact.Location(path, offset, size, start_line, 
                     start_column, end_line, end_column)
    end
  end
end

if __FILE__ == $0 then
  require 'core/grammar/parse/origins'
  gg = Load::load('grammar.grammar')
  src = File.read('core/expr/models/expr.grammar') # "start A A ::= \"a\""
  #src = "start Expr Expr ::= ETernOp | BLA Bla ::= \"a\""
  #src = '([X])'
  
  RubyProf.start

  x = EnsoGLL::parse(src, gg, Origins.new(src, "-"), 'Grammar')

  result = RubyProf.stop

  printer = RubyProf::FlatPrinter.new(result)
  printer.print(STDOUT)
  puts x
  File.open('sppf.dot', 'w') do |f|
    ToDot.to_dot(x, f)
  end
end


require 'core/grammar/tools/todot'
require 'core/grammar/parse/sharing-factory'
require 'core/schema/tools/print'
require 'core/schema/tools/copy'
require 'core/grammar/parse/scan'
require 'core/system/load/load'


module EnsoGLL
  def self.parse(source, grammar, start_symbol, org)
    EnsoGLLParser.new.parse(source, grammar, start_symbol, org)
  end


  class EnsoGLLParser
    def parse(source, grammar, start_symbol, org)
      @todo = []
      @done = {}
      @toPop = {}
      @iters = {}
      

      #puts "PARSING SOURCE:"
      #puts source

      @schema = Load::load('grammar.schema')
      shared = [@schema.classes["Base"],
                @schema.classes["Leaf"],
                @schema.classes["Node"],
                @schema.classes["Empty"],
                @schema.classes["Item"],
                @schema.classes["Edge"],
                @schema.classes["Pack"],
                @schema.classes["GSS"]]

      @fact = SharingFactory::new(@schema, shared)
      @grammar =  Copy.new(@fact).copy(grammar)


      #HACK
      start_rule = @grammar.rules[start_symbol]

      @origins = org

      @scan = Scan.new(@grammar, source)
      @ws, @start_pos = @scan.skip_ws
      @epsilon = @fact.Epsilon

      
      @dummy_loc = @fact.Location("", 0, 0, 0, 0, 0, 0)
      @dummy_node = @fact.Leaf(0, 0, @epsilon, @dummy_loc, "$DUMMY$", "")


      @start_with = @fact.Create("INTERNAL_ROOT", 
                                 @fact.Sequence([@fact.Call(start_rule)]))

      start_item = @fact.Item(@start_with, [@start_with], 1)

      @ci = @start_pos
      @cu = @start = @fact.GSS(start_item, 0)
      @cn = @dummy_node
      #puts "CN start = #{@cn}"


      #add(@start_with)
      add(@fact.Item(@start_with, [@start_with], 0))
      dispatch
      result(source, @start_with)
    end

    def debug(msg)
      puts msg
    end

    def dispatch
      while !@todo.empty? do
        parser, @cu, @cn, @ci = @todo.shift
        debug "ci = #{@ci}"
        debug "PARSER = #{parser}"
        debug "CU = #{@cu}"
        debug "CN = #{@cn}"
        #debug "-------------> TODO = #{@todo}"
        debug "CI = #{@ci}"
        eval(parser, nil)
      end
    end

    def eval(this, nxt)
      send(this.schema_class.name, this, nxt)
    end

    def Item(this, _)
      debug "-----------------> ITEM: #{this}"
      if this.dot == this.elements.size then
        pop
      else
        nxt = @fact.Item(this.expression, this.elements, this.dot + 1)
        eval(this.elements[this.dot], nxt)
      end
    end

    def Sequence(this, nxt)
      add(@fact.Item(this, this.elements, 0))

      # if this.elements.empty? then
      #   create(nxt) if nxt # this is needed to make sure chaining
      #   # works correctly in case the leaf is empty; otherwise
      #   # we lose empty Creates which are needed to make "empty" objects.

      #   empty_node(item, @epsilon)
      #   Item(nxt, nil) if nxt
      # else
      #   create(nxt) if nxt
      #   Item(item, nil)
      # end
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

    def Rule(this, nxt)
      # chain(this, nxt)
      create(nxt) if nxt
      this.arg.alts.each do |x|
        if x.Sequence? then
          add(@fact.Item(this, x.elements, 0))
        else # Create
          add(@fact.Item(this, [x], 0))
        end
      end
    end

    def Call(this, nxt)
      #create(nxt) if nxt
      eval(this.rule, nxt)
      # #TODO: arg is always Alt per the grammar
      # #but this is not reflected in the schema
      # this.rule.arg.alts.each do |alt|
      #   debug "ADDING ALT: #{alt} from calling #{this} to #{this.rule.name} cu = #{@cu}"
      #   add(alt)
      # end
    end

    def Create(this, nxt)
      create(nxt) if nxt
      add(@fact.Item(this, this.arg.elements, 0))
      # if this.arg.Sequence? then
      #   add(@fact.Item(this, this.arg.elements, 0))
      # else
      #   add(@fact.Item(this, this.arg, 0))
      # end
      #chain(this, nxt)
    end

    def Field(this, nxt)
      create(nxt) if nxt
      add(@fact.Item(this, [this.arg], 0))
    end

    def Alt(this, nxt)
      create(nxt) if nxt
      this.alts.each do |alt|
        debug "ADDING ALT (Alt): #{alt}"
        # add(alt)
        add(@fact.Item(this, [alt], 0))
      end
    end

    def Code(this, nxt)
      terminal(this, @ci, '', '', nxt)
    end

    def Lit(this, nxt)
      @scan.with_literal(this.value, @ci) do |pos, ws|
        debug "LIT success: #{this} (at #{@ci})"
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
        debug "VALUE success: #{this} at #{@ci}"
        terminal(this, pos, tk, ws, nxt)
      end
    end

    def Regular(this, nxt)
      create(nxt) if nxt
      if !this.many && this.optional then
        add(@fact.Item(this, [@epsilon], 0))
        add(@fact.Item(this, [this.arg], 0))
      elsif this.many && !this.optional && !this.sep then
        add(@fact.Item(this, [this.arg], 0))
        add(@fact.Item(this, [this.arg, this], 0))
      elsif this.many && this.optional && !this.sep then
        add(@fact.Item(this, [@epsilon], 0))
        add(@fact.Item(this, [this.arg, this], 0))
      elsif this.many && !this.optional && this.sep then
        add(@fact.Item(this, [this.arg], 0)) 
        add(@fact.Item(this, [this.arg, this.sep, this], 0))
      elsif this.many && this.optional && this.sep then
        @iters[this] ||= @fact.Regular(this.arg, false, true, this.sep)
        #sym = @fact.Regular(this.arg, false, true, this.sep)
        add(@fact.Item(this, [@epsilon], 0))
        add(@fact.Item(this, [@iters[this]], 0))
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
      debug "TERMINAL NODE: #{cr}"
      if nxt then
        item_node(nxt, cr)
        Item(nxt, nil)
      end
    end

    def result(source, top)
      # TODO: not only Node!!!
      max = -1
      last = nil
      r = @fact._objects_for(@schema.classes['Node']).find do |n|
        #debug "\tstart: #{n.starts}"
        #debug "\tend: #{n.ends}"
        #debug "\ttype: #{n.type}"
        if n.starts == @start_pos && n.ends > max then
          last = n
          max = n.ends
        end
        top_node?(n, source, top)
      end
      if r then
        #r.kids[0].right
        r
      else
        File.open('last-sppf.dot', 'w') do |f|
          ToDot.to_dot(last, f)
        end
        raise "Parser error #{@ci}"
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
      if !@done[i][conf]
        @done[i][conf] = true
        @todo << [parser, u, w, i]
        debug "Descriptor added: parser = #{parser}, gss = #{u}, i = #{i}, node = #{w}"
      else
        #debug "NOT ADDED: parser = #{parser}, gss = #{u}, i = #{i}, node = #{w}"
      end
    end

    def pop
      debug "POP: cu.item = <#{@cu.item.expression}, #{@cu.item.elements}, #{@cu.item.dot}>, ci = #{@ci}, node = #{@cn.type}"
      
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
          debug "----> X = #{x}: #{x.type}, W = #{w.type}, cn = #{@cn.type}"
          add(cnt, u, @ci, x)
        end
      end
    end

    def create(item)
      w = @cn
      v = @fact.GSS(item, @ci)
      #debug "W = #{w}"
      #debug "CU = #{@cu}"
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
      # change to Empty!!
      cr = @fact.Empty(@ci, @ci, eps, origin(@ci, @ci), "", "")
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
      debug "LEAF: #{cr} pos = #{pos} ci = #{@ci}"
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
        #debug "ITEM.EXPRESSION (= t): #{t}"
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
  src = "start Expr Expr ::= ETernOp | BLA Bla ::= \"a\""
  src = '(a: X)'
  x = EnsoGLL::parse(src, gg, 'Pattern', Origins.new(src, "-"))
  puts x
  File.open('sppf.dot', 'w') do |f|
    ToDot.to_dot(x, f)
  end
end

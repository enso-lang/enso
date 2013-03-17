
require 'core/grammar/tools/todot'
require 'core/grammar/parse/gll-factory'
require 'core/grammar/parse/sharing-factory'
require 'core/schema/tools/print'
require 'core/schema/tools/copy'
require 'core/schema/tools/todot'
require 'core/grammar/parse/scan2'
require 'core/grammar/parse/normalize'
require 'core/grammar/parse/itemize'
require 'core/grammar/parse/deformat'
require 'core/grammar/parse/layout'
require 'core/system/load/load'
require 'ruby-prof'

module EnsoGLL
  def self.parse(source, grammar, org)
    EnsoGLLParser.new(grammar).parse(source, org)
  end


  class EnsoGLLParser
    include Interpreter::Dispatcher


    def initialize(grammar, fact = GLLFactory::new)
      @fact = fact
      if fact.is_a?(GLLFactory::GLLFactoryClass) then
        @gfact = Factory::new(Load::load('parsing.schema'))
      else
        @gfact = fact
      end
      @grammar =  Copy.new(@gfact).copy(grammar)

      # Use start from copied model.
      start = @grammar.start

      
      $stderr << "## initializing grammar for #{start.name}...\n"
      $stderr << "## removing formatting...\n"
      DeformatGrammar::deformat(@grammar)

      $stderr << "## normalizing...\n"
      NormalizeGrammar::normalize(@grammar)

      s = @gfact.Rule
      s.name = '__START__'
      s.arg = @gfact.Alt
      s.arg.alts << @gfact.Sequence
      call = @gfact.Call
      call.rule = start
      s.arg.alts[0].elements << @gfact.Layout
      s.arg.alts[0].elements << call
      s.arg.alts[0].elements << @gfact.Layout
      @grammar.rules << s
      @start = s

      
      $stderr << "## adding layout...\n"
      LayoutGrammar::layout(@grammar)

      $stderr << "## adding items...\n"
      ItemizeGrammar::itemize(@grammar)


      @epsilon = @gfact.Sequence
    end



    def parse(source, org)
      $stderr << "## parsing #{org.path}...\n"
      @todo = []
      @done = {}
      @toPop = {}
      @iters = {}

      @origins = org

      @scan = Scan2.new(@grammar, source)

      dummy_rule = @gfact.Rule
      dummy_rule.name = "BALABALBAL"
      dummy = @gfact.Call(nil, nil, dummy_rule)

      @ci = 0
      @cu = @start_gss = @fact.GSS(dummy, 0)
      @cn = nil 

      @start.arg.alts.each do |x|
        #puts "item = #{x.elements[0]}"
        add(x.elements[0])
      end
      while !@todo.empty? do
        parser, @cu, @cn, @ci = @todo.pop #shift
        #puts "PARSING: cu = #{@cu}, cn = #{@cn}, ci = #{@ci}"
        eval(parser)
      end
      $stderr << "## done.\n"
      result(source, @start)
    end

    def eval(this)
      ##puts "Dispatching to #{this}"
      send(this.schema_class.name, this)
    end

    def End(this)
      #puts "---------------------> END #{this}  rule =#{this.nxt}"
      pop
    end
    
    def EpsilonEnd(this)
      #puts "EPSILON #{this.nxt}"
      cr = @fact.Leaf(@ci, @ci, @epsilon, nil, "")
      # cr.starts = @ci
      # cr.ends = @ci
      # cr.type = @epsilon
      # cr.value = ""
      #puts "EMPTY NODE = #{cr}"
      @cn = make_node(this, @cn, cr)
      pop
    end



    def Rule(this)
      this.arg.alts.each do |x|
        #if x.elements.empty? then
        #  cr = @fact.Leaf(@ci, @ci, @epsilon, 0, "")
        #  @cn = make_node(this, @cn, cr)
        #  pop
        #else
        add(x.elements[0])
        #end
      end
    end

    def terminal(type, pos, value)
      cr = @fact.Leaf(@ci, pos, type, origin(@ci, pos), value)
      @ci = pos
      #puts "TERMINAL: #{type}"
      #puts "TERMINAL prev: #{type.prev}"
      #puts "TERMINAL next: #{type.nxt}"

      if type.prev.nil? && !type.nxt.End? then
        @cn = cr
      else
        @cn = make_node(type.nxt, @cn, cr)
      end
      eval(type.nxt)
    end


    def Call(this)
      #puts "CALL: #{this.rule.name}"
      create(this.nxt)
      eval(this.rule)
    end

    def Code(this)
      terminal(this, @ci, '')
    end

    def Lit(this)
      @scan.with_literal(this.value, @ci) do |pos|
        terminal(this, pos, this.value)
      end
    end

    def Layout(this)
      @scan.with_layout(@ci) do |pos, ws|
        terminal(this, pos, ws)
      end
    end

    def Ref(this)
      @scan.with_token('sym', @ci) do |pos, tk|
        terminal(this, pos, tk)
      end
    end

    def Value(this)
      @scan.with_token(this.kind, @ci) do |pos, tk|
        terminal(this, pos, tk)
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
      node.starts == 0 && 
        node.ends == source.size  &&
        node.type == top
    end
    
    def add(parser, u = @cu, i = @ci, w = nil) 
      if !@done.has_key?(i) then
        @done[i] = {}
      end
      conf = [parser, u, w]
      if !@done[i][conf]
        @done[i][conf] = true
        @todo.push [parser, u, w, i]
      end
    end

    def pop
      if @cu.equals(@start_gss) then
        nil
      else
        if !@toPop.has_key?(@cu) then
          @toPop[@cu] = {}
        end
        if !@toPop[@cu].has_key?(@cn) then
          @toPop[@cu][@cn] = @cn
        end
        cnt = @cu.item
        #puts "CNT #{cnt}"
        @cu.edges.each do |edge| #|w, gs|
          w = edge.sppf
          u = edge.target
          #puts "POP WWWW: #{w}"
          #puts "POP UUUU: #{u}"
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

    def is_second_but_not_last?(item)
      #if item.dot == 1 && item.elements.size > 1 then
      # a . b c 
      return false if item.prev.nil?
      #item.prev.Terminal? && 
      item.prev.prev.nil? && !item.End?
    end
      
    def make_node(item, z, w)
      if is_second_but_not_last?(item) then
        #puts "PREV = #{item.prev}; prev.prev = #{item.prev && item.prev.prev}"
        #puts "returning w = #{w} because of #{item}"
        return w
      end
      #puts "MAKENODE item: #{item}"
      #puts "z = #{z}"
      #puts "w = #{w}"
      t = item
      if item.End? then
        t = item.nxt # the rule
        raise "Item.nxt = nil" if t.nil?
      end
      x = w.type
      k = w.starts
      
      i = w.ends
      if z != nil then
        s = z.type
        j = z.starts
        # assert k == z.ends
        y = @fact.Node(j, i, t, nil)
        pack = @fact.Pack(y, item, k, z, w)
        if !y.kids.include?(pack)
          y.kids << pack
        end
      else
        y = @fact.Node(k, i, t, nil)
        pack = @fact.Pack(y, item, k, nil, w)
        if !y.kids.include?(pack)
          y.kids << pack
        end
      end
      #puts "Returning y = #{y}"
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
  require 'core/grammar/parse/enso-build'

  gg = Load::load('grammar.grammar')
  gs = Load::load('grammar.schema')
  #src = File.read('core/expr/models/expr.grammar') # "start A A ::= \"a\""
  src = "  start Expr Expr ::= Expr op:\"+\" Expr"
  #src = '{a == b}'
  #src = '(a)'
  #src = '()'
  #src = "X ::="


  ps = Load::load('parsing.schema')
  shares = [ps.classes["Node"],
            ps.classes["Leaf"],
            ps.classes["Pack"],
            ps.classes["GSS"],
            ps.classes["Edge"]]

  parser = EnsoGLL::EnsoGLLParser.new(gg, SharingFactory.new(ps, shares))

  #RubyProf.start
  org = Origins.new(src, "-")
  x = parser.parse(src, org)

  puts x
  File.open('sppf.dot', 'w') do |f|
    ToDot.to_dot(x, f)
  end
  
  obj = EnsoBuild::build(x, SharingFactory.new(ps, shares), org, [])
  
  Layout::DisplayFormat.print(gg, obj, $stdout, false)

  NormalizeGrammar::normalize(obj)
  LayoutGrammar::layout(obj)
  ItemizeGrammar::itemize(obj)
  
  t = ObjectToDot.new
  File.open('normalized.dot', 'w') do |f|
    t.todot(obj, f)
  end

  
  #result = RubyProf.stop

  #printer = RubyProf::FlatPrinter.new(result)
  #printer.print(STDOUT)



  ss = Load::load('grammar.schema')
  f = Factory::new(ss)
  grammar = f.Grammar
  rule = f.Rule
  rule.name = "X"
  rule.arg = f.Alt
  seq = f.Sequence
  rule.arg.alts << seq

  ruleA = f.Rule
  ruleA.name = "A"
  ruleA.arg = f.Alt
  seqA = f.Sequence
  ruleA.arg.alts << seqA

  ruleB = f.Rule
  ruleB.name = "B"
  ruleB.arg = f.Alt
  seqB = f.Sequence
  ruleB.arg.alts << seqB

  call = f.Call
  call.rule = ruleA
  callB = f.Call
  callB.rule = ruleB

  seq.elements << call
  seq.elements << callB

  lit = f.Lit
  lit.value = "c"
  seq.elements << lit
 
  lit = f.Lit
  lit.value = "a"
  seqA.elements << lit
 

  lit = f.Lit
  lit.value = "b"
  seqB.elements << lit
  
  
  grammar.start = rule
  grammar.rules << rule
  grammar.rules << ruleA
  grammar.rules << ruleB
  
  grammar.finalize

  #RubyProf.start

  src = "a b c"

  require 'core/grammar/parse/parse'
  source = <<-EOG
start S
S ::= "a" S | A S "d" | 
A ::= "a"
EOG
  grammar = Parse::load_raw(source, gg,ss , f, imports = [], show = false, filename = '-')
  src = "a a d"



  source = <<-EOG
start S
S ::= A | B
A ::= "a"
B ::= "a"
EOG
  grammar = Parse::load_raw(source, gg,ss , f, imports = [], show = false, filename = '-')

  src = "a"



  source = <<-EOG
start S
S ::= A C | B
A ::= "a"
B ::= "a"
C ::= 
EOG
  grammar = Parse::load_raw(source, gg,ss , f, imports = [], show = false, filename = '-')

  src = "a"


  source = <<-EOG
start S
S ::= A C 
A ::= "a"
C ::= 
EOG
  grammar = Parse::load_raw(source, gg,ss , f, imports = [], show = false, filename = '-')


   source = <<-EOG
start S
S ::= A+ 
A ::= "a"
EOG
  grammar = Parse::load_raw(source, gg,ss , f, imports = [], show = false, filename = '-')


  src = "a a a"


  #x = EnsoGLL::parse(src, grammar, Origins.new(src, "-"), 'S')


  #result = RubyProf.stop

  #printer = RubyProf::FlatPrinter.new(result)
  #printer.print(STDOUT)
end

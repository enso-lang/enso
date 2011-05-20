#### pop when creating a node (like reduce)

require 'set'
require 'ostruct'

require 'core/grammar/code/gll/gss'
require 'core/grammar/code/gll/todot'
require 'core/grammar/code/gll/sppf'
require 'core/grammar/code/gll/scan'
require 'core/grammar/code/gll/parsers'


class GLL
  include Scanner
  include Parsers

  def self.parse(source, grammar, top = grammar.start)
    GLL.new.parse(source, grammar, top)
  end


  def init_parser(grammar, top)
    @gf = grammar._graph_id
    @todo = []
    @done = {}
    @toPop = {}

    # TODO: move these tables to here
    Node.nodes.clear
    GSS.nodes.clear

    # caches for dynamically created
    # grammar things
    @items = {}
    @epsilon = @gf.Epsilon
    @seps = {}
    @iters = {}

    @ws, @begin = skip_ws # NB: requires init_scanner to have been executed
    @ci = @begin
    @start = GSS.new(item(top.arg, [top.arg], 1), 0)
    @cu = @start
    @cn = nil
  end

  def item(exp, elts, dot)
    key = [exp, elts, dot]
    @items[key] ||= @gf.Item(exp, elts, dot)
  end

  def parse(source, grammar, top)
    init_scanner(grammar, source)
    init_parser(grammar, top)
    add(top)
    while !@todo.empty? do
      parser, @cu, @cn, @ci = @todo.shift
      recurse(parser)
    end
    result(source, top)
  end

  def result(source, top)
    #puts "/* GSS: #{GSS.nodes.length} */"
    #puts "/* Nodes: #{Node.nodes.length} */"
    #puts "CI: #{@ci}"
    last = 0;
    pt = Node.nodes.values.find do |n|
      if n.starts == @begin then
        last = n.ends > last ? n.ends : last
      end
      n.is_a?(Node) && n.starts == @begin && n.ends == source.length && n.type == top
    end
    raise "Parse error at #{last}:\n'#{source[last,50]}...'" unless pt
    File.open('sppf.dot', 'w') do |f|
      ToDot.to_dot(pt, f)
    end
    return pt
  end
  
  def add(parser, u = @cu, i = @ci, w = nil) 
    #puts "Adding #{parser} (i = #{i}, u =  #{u}, w = #{w})"
    @done[i] ||= {}
    conf = [parser, u, w]
    unless @done[i][conf]
      @done[i][conf] = true
      @todo << [parser, u, w, i]
    end
  end

  def pop
    return if @cu == @start
    @toPop[@cu] ||= {}
    @toPop[@cu][@cn] ||= @cn
    cnt = @cu.parser
    @cu.edges.each do |w, gs|
      gs.each do |u|
        x = Node.new(cnt, w, @cn)
        #puts "Adding in pop"
        add(cnt, u, @ci, x)
      end
    end
  end

  def create(parser)
    w = @cn
    v = GSS.new(parser, @ci)
    if v.add_edge(w, @cu) then
      if @toPop[v] then
        @toPop[v].each_key do |z|
          x = Node.new(parser, w, z)
          add(parser, @cu, z.starts, z)
        end
      end
    end
    return v
  end

  def recurse(this, *args)
    #puts "Sending #{this.schema_class.name}"
    send(this.schema_class.name, this, *args)
  end

  def chain(this, nxt)
    @cu = create(nxt) if nxt
    add(item(this, [this.arg], 0))
  end

  def continue(nxt)
    Item(nxt) if nxt
  end

  def empty(item, nxt)
    cr = Empty.new(@ci, @epsilon)
    @cn = Node.new(item, @cn, cr)
    pop
    continue(nxt)
  end

  def terminal(type, pos, value, ws, nxt)
    cr = Leaf.new(@ci, pos, type, value, ws)
    @ci = pos
    if nxt then
      @cn = Node.new(nxt, @cn, cr)
      continue(nxt)
    end
  end
end


if __FILE__ == $0 then
  require 'core/grammar/code/gll/gamma2'
  require 'core/schema/tools/print'
  require 'core/grammar/code/gll/implode'
  require 'core/system/boot/grammar_grammar'
  require 'core/grammar/code/layout'

  gg = GrammarGrammar.grammar 
  src = File.read('core/grammar/models/grammar.grammar')
  sppf2 = GLL.new.parse(src, gg, gg.start)


  require 'core/grammar/code/gll/todot'

  File.open('sppf.dot', 'w') do |f|
    ToDot.to_dot(sppf2, f)
  end
                 
  exit!
       
  ast = Implode.implode(sppf2)
  puts "AST: #{ast}"

  exit!

  Print.print(ast)

  require 'core/instance/code/instantiate'
  
  gf = Factory.new(GrammarSchema.schema)
  obj = Instantiate.instantiate(gf, ast)
  puts "OBJ = #{obj}"



  obj.rules.each do |r|
    puts "#{r.name} ::= #{r.arg}"
    r.arg.alts.each do |alt|
      puts alt.to_s
    end
  end

  Print.print(obj)
  DisplayFormat.print(GrammarGrammar.grammar, obj)
end
  

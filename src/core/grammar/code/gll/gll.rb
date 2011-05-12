#### pop when creating a node (like reduce)

require 'set'
require 'ostruct'

require 'core/grammar/code/gll/gss'
require 'core/grammar/code/gll/sppf'
require 'core/grammar/code/gll/scan'
require 'core/grammar/code/gll/grammar'


class GLL
  include Scanner
  include Symbols

  def init_parser(grammar, top)
    @gf = grammar._graph_id
    @todo = []
    @done = {}
    @toPop = {}

    # caches for dynamically created
    # grammar things
    @items = {}
    @epsilon = @gf.Epsilon
    @seps = {}


    @ws, @begin = skip_ws # NB: requires init_scanner to have been executed
    @ci = @begin
    @start = GSS.new(item(top.arg, [top.arg], 1), 0)
    @cu = @start
    @cn = nil
  end

  def item(exp, elts, dot)
    key = [exp, elts, dot]
    unless @items[key] then
      @items[key] = @gf.Item(exp, elts, dot)
    end
    @items[key]
  end

  def parse(grammar, source, top)
    init_scanner(grammar, source)
    init_parser(grammar, top)
    add(top)
    while !@todo.empty? do
      parser, @cu, @cn, @ci = @todo.shift
      recurse(parser)
    end
    puts "/* GSS: #{GSS.nodes.length} */"
    puts "/* Nodes: #{Node.nodes.length} */"
    ws, _ = skip_ws
    Node.nodes.each do |k, n|
      if n.starts == @begin && n.ends == source.length - ws.length  && n.type == top then
        return n
      else
        # temp. hack
        Node.nodes.delete(k)
      end
    end
    raise "Parse error"
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
    #continue()
  end

  def continue(nxt)
    Item(nxt) if nxt
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
  #src = "b " * 10
  #gamma2 = Gamma2.grammar
  #GLL.new.parse(gamma2, src, gamma2.start)

#   src = "x + x + x"
#   exp = Exp.grammar
#   GLL.new.parse(exp, src, exp.start)

#   src = "[x x x x]"
#   lst = Lists.grammar
#   sppf = GLL.new.parse(lst, src, lst.start)


#   ast = Implode.implode(sppf)
#   puts "AST: #{ast}"


#   Print.print(ast)
  
  require 'core/schema/tools/print'
  require 'core/grammar/code/gll/implode'
  require 'core/system/boot/grammar_grammar'

  gg = GrammarGrammar.grammar 
  src = File.read('core/grammar/models/grammar.grammar')
  sppf2 = GLL.new.parse(gg, src, gg.start)


  dot = ''
  Node.to_dot(dot)
  File.open('bla.dot', 'w') do |f|
    f.write(dot)
  end

                        
  ast = Implode.implode(sppf2)
  puts "AST: #{ast}"


  Print.print(ast)

  require 'core/instance/code/instantiate'
  
  gf = Factory.new(GrammarSchema.schema)
  obj = Instantiate.instantiate(gf, ast)
  puts "OBJ = #{obj}"

end
  

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
    @ci = 0
    @start = GSS.new(@gf.Item(top.arg, [top.arg], 1), 0)
    @cu = @start
    @cn = nil
    @todo = []
    @done = {}
    @toPop = {}
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
    Node.nodes.each_value do |n|
      if n.starts == 0 && n.ends == source.length then
        return n
      end
    end
    raise "Parse error"
  end
  
  def add(parser, u = @cu, i = @ci, w = nil) 
    #puts "Adding #{parser} (i = #{i}, u =  #{u}, w = #{w})"
    @done[i] ||= []
    conf = [parser, u, w]
    unless @done[i].include?(conf)
      @done[i] << conf
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
    continue(@gf.Item(this, [this.arg], 0))
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

  src = "[x x x x]"
  lst = Lists.grammar
  sppf = GLL.new.parse(lst, src, lst.start)

  dot = ''
  Node.to_dot(dot)
  File.open('bla.dot', 'w') do |f|
    f.write(dot)
  end

  require 'core/grammar/code/gll/implode'
  ast = Implode.implode(sppf)
  puts "AST: #{ast}"


  require 'core/schema/tools/print'
  Print.print(ast)

end
  

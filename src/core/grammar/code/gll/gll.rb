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

  def self.parse(source, grammar, top, org)
    self.new(org).parse(source, grammar, top)
  end

  def initialize(org, dot_output = nil)
    @origins = org
    @dot_output = dot_output
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
    last = 0;
    pt = Node.nodes.values.find do |n|
      last = n.ends > last ? n.ends : last
      n.is_a?(Node) && n.starts == @begin && n.ends == source.length && n.type == top
    end
    unless pt
      loc = @origins.str(last)
      raise "Parse error at #{loc}:\n'#{source[last,50]}...'" 
    end
    ToDot.to_dot(pt, @dot_output) if @dot_output
    return pt
  end
  
  def add(parser, u = @cu, i = @ci, w = nil) 
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
    cnt = @cu.item
    @cu.edges.each do |w, gs|
      gs.each do |u|
        x = Node.new(cnt, w, @cn)
        add(cnt, u, @ci, x)
      end
    end
  end

  def create(item)
    w = @cn
    v = GSS.new(item, @ci)
    if v.add_edge(w, @cu) then
      if @toPop[v] then
        @toPop[v].each_key do |z|
          x = Node.new(item, w, z)
          add(item, @cu, z.ends, x)
        end
      end
    end
    return v
  end

  def recurse(this, *args)
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
    # NB: pos includes the ws that has ben matched
    # so subtract the length of ws from pos.
    # TODO: fix this consistently: introduce
    # two positions (incl and excl ws)
    # currently this is undone in Leaf#ends
    cr = Leaf.new(@ci, pos - ws.length, type, value, ws)
    @ci = pos
    if nxt then
      @cn = Node.new(nxt, @cn, cr)
      continue(nxt)
    end
  end
end


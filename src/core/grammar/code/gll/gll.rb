
require 'core/grammar/code/gll/gss'
require 'core/grammar/code/gll/todot'
require 'core/grammar/code/gll/sppf'
require 'core/grammar/code/gll/eval'


class GLL
  attr_reader :ci

  def self.parse(source, grammar, top, org)
    self.new.parse(source, grammar, top, org)
  end

  def parse(source, grammar, top, org)
    @todo = []
    @done = {}
    @toPop = {}

    @origins = org

    # TODO: move these tables to here
    Node.nodes.clear
    GSS.nodes.clear

    eval = GrammarEval.new(grammar, source, top)
    @start_pos = @ci = eval.start_pos
    @cu = @start = GSS.new(eval.start, 0)
    @cn = nil

    add(top)
    dispatch(eval)
    result(source, top)
  end

  def dispatch(eval)
    while !@todo.empty? do
      parser, @cu, @cn, @ci = @todo.shift
      eval.eval(parser, self, nil)
    end
  end

  def result(source, top)
    last = 0;
    pt = Node.nodes.values.find do |node|
      last = node.ends > last ? node.ends : last
      top_node?(node, source, top)
    end
    unless pt
      loc = @origins.str(last)
      raise "Parse error at #{loc}:\n'#{source[last,50]}...'" 
    end
    return pt
  end
  
  def top_node?(node, source, top)
    node.is_a?(Node) &&
      node.starts == @start_pos && 
      node.ends == source.length  &&
      node.type == top
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
    @cu = v
  end

  def empty_node(item, eps)
    cr = Empty.new(@ci, eps)
    item_node(item, cr)
    pop
  end

  def item_node(item, cr)
    @cn = Node.new(item, @cn, cr)
  end

  def leaf_node(pos, type, value, ws)
    # NB: pos includes the ws that has been matched
    # so subtract the length of ws from pos.
    cr = Leaf.new(@ci, pos - ws.length, type, value, ws)
    @ci = pos
    return cr
  end
end


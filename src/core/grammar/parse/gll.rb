
require 'core/grammar/parse/gss'
require 'core/grammar/tools/todot'
require 'core/grammar/parse/sppf'
require 'core/grammar/parse/eval'
require 'core/schema/tools/print'

class GLL
  include SPPF
  include GSS
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
    r = Node.nodes.values.find do |n|
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
    node.is_a?(Node) &&
      node.starts == @start_pos && 
      node.ends == source.length  &&
      node.type.equals(top)
  end
  
  def add(parser, u = @cu, i = @ci, w = nil) 
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
      # @toPop[@cu] ||= {}
      # @toPop[@cu][@cn] ||= @cn
      cnt = @cu.item
      @cu.edges.each do |w, gs|
        gs.each do |u|
          x = Node.new(cnt, w, @cn)
          add(cnt, u, @ci, x)
        end
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
    cr
  end
end


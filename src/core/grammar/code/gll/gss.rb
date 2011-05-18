
require 'set'

class GSS
  attr_reader :parser, :pos, :edges

  @@nodes = {}
  
  def self.new(*args)
    @@nodes[args] ||= super(*args)
  end

  def self.nodes
    @@nodes
  end

  
  def initialize(parser, pos)
    @parser = parser
    @pos = pos
    @edges = {}
    @hash = parser.hash * 3 + pos * 17
  end

  def add_edge(node, gss)
    edges[node] ||= Set.new
    if edges[node].include?(gss) then
      return false
    else
      edges[node] << gss
      return true
    end
  end
  
  def ==(o)
    return true if self.equal?(o)
    return false unless o.is_a?(GSS)
    return parser == o.parser && pos == o.pos
  end

  def hash
    @hash
  end
end

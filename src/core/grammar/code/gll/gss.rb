
require 'set'

class GSS
  attr_reader :item, :pos, :edges

  @@nodes = {}
  
  def self.new(*args)
    @@nodes[args] ||= super(*args)
  end

  def self.nodes
    @@nodes
  end
  
  def initialize(item, pos)
    raise if item.schema_class.name != 'Item'
    @item = item
    @pos = pos
    @edges = {}
    @hash = item.hash * 3 + pos * 17
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
    return item == o.item && pos == o.pos
  end

  def hash
    @hash
  end

  def to_s
    "GSS(#{item} @ #{pos})"
  end
end


module GSS

  class GSS
    attr_reader :item, :pos, :edges

    @@nodes = {}
    
    def self.new(*args)
      if !@@nodes.has_key?(args) then
        @@nodes[args] = super(*args)
      else
        @@nodes[args]
      end
      # @@nodes[args] ||= super(*args)
    end

    def self.nodes
      @@nodes
    end
    
    def initialize(item, pos)
      # raise if item.schema_class.name != 'Item'
      @item = item
      @pos = pos
      @edges = {}
      @hash = item.hash * 3 + pos * 17
    end

    def add_edge(node, gss)
      if !edges.include?(node) then
        edges[node] = []
      end
      #edges[node] ||= Set.new
      if edges[node].include?(gss) then
        false
      else
        edges[node] << gss
        true
      end
    end
    
    # def ==(o)
    #   return true if self.equal?(o)
    #   return false unless o.is_a?(GSS)
    #   return item == o.item && pos == o.pos
    # end


    def equals(o)
      if self.equal?(o) then
        true
      elsif !o.is_a?(GSS) then
        false
      else
        item.equals(o.item) && pos == o.pos
      end
    end

    def eql?(o)
      equals(o)
    end

    def hash
      @hash
    end

    def to_s
      "GSS(#{item} @ #{pos})"
    end
  end
end


require 'set'

class BaseNode
  attr_reader :type, :starts, :ends, :id

  # TODO: remove the global variable
  # cannot resue it for multiple parses
  @@nodes = {}

  def self.nodes
    @@nodes
  end

  def self.to_dot(out)
    i = 0
    visited = {}
    out << "digraph forest {\n"
    out << "order = out;\n"
    @@nodes.each_value do |n|
      i = n.ids(i)
      n.to_dot(out, visited)
    end
    out << "}\n"
  end

  def ids(n)
    return n if @id
    @id = n += 1
    kids.each do |k|
      n = k.ids(n)
    end
    return n
  end

  def to_dot(out, visited)
    return if visited[self]
    visited[self] = true
    out << "node#{id} [shape=#{shape},label=\"#{label}\"]\n"
    kids.each do |k|
      k.to_dot(out, visited)
      out << "node#{id} -> node#{k.id}\n"
    end
  end


  def kids
    []
  end

  def self.new(*args)
    # ugly, remove Pack from Node hierarchy
    # it's currently in there just because of todot
    return super(*args) if self.to_s == 'Pack'
    @@nodes[args] ||= super(*args)
    #     x = super(*args)
    #     unless @@nodes[x]
    #       @@nodes[x] = x
    #     end
    #     @@nodes[x]
  end

  def initialize(starts, ends, type)
    @starts = starts
    @ends = ends
    @type = type
    @hash = 29 * self.class.to_s.hash + 37 * starts + 17 * ends
  end

  def hash
    @hash
  end
end

class Leaf < BaseNode
  attr_reader :token
  attr_reader :ws

  # TODO: type = nil ==> empty (from GrammarSchema)
  def initialize(starts, ends = starts, type = nil, token = nil, ws = nil)
    super(starts, ends, type)
    @token = token
    @ws = ws
    @hash += 13 * token.hash
  end

  def ==(x)
    return true if self.equal?(x)
    return false unless x.is_a?(Leaf)
    super(x) && @token == x.token
  end

  def label
    "#{token}(#{starts},#{ends})"
  end

  def shape
    "plaintext"
  end

end

class Node < BaseNode
  attr_reader :kids

  def self.new(item, current, nxt)
    if item.dot == 1 && item.elements.length > 1 then
      return nxt
    end
    #return nxt unless current
    k = nxt.starts
    i = nxt.ends
    j = k
    j = current.starts if current
    puts "// Making node: #{item.at_end?} => #{item.expression}"
    at_end = item.dot == item.elements.length
    y = super(j, i, at_end ? item.expression : item)
    y << Pack.new(item, k, current, nxt)
    return y
  end

  def initialize(starts, ends, type)
    super(starts, ends, type)
    @kids = []
    @hash += 13 * type.hash
  end
  
  def <<(n)
    @kids << n
  end

  def ==(x)
    return true if self.equal?(x)
    return false unless x.is_a?(Node)
    super(x) && type == x.type
  end

  def label
    i = type.to_s.gsub(/"/, '\\"')
    "#{i}(#{starts},#{ends})"
  end

  def shape
    'box'
  end

end

class Pack < BaseNode
  attr_reader :parser, :pivot, :left, :right, :id

  def initialize(parser, pivot, left, right)
    @parser = parser
    @pivot = pivot
    @left = left
    @right = right
  end

  def kids
    [left, right].compact
  end

  def shape
    'point'
  end

  def label
    ''
  end

  def hash
    "pack".hash + 31 * pivot
  end

end

    

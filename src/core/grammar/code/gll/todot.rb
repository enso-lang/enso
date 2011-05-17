


class ToDot

  def self.to_dot(sppf, out = $stdout)
    ToDot.new(sppf, out).to_dot
  end

  def initialize(sppf, out)
    @sppf = sppf
    @out = out
  end

  def to_dot
    @out << "digraph SPPF {\n"
    nodes = ident(@sppf)
    nodes(nodes)
    edges(nodes)
    @out << "}\n"
  end

  def ident(sppf) 
    nodes = {}
    id = 0
    todo = [sppf]
    while !todo.empty? do
      node = todo.shift
      node.kids.each do |k|
        if !nodes[k] then
          nodes[k] = id += 1
          todo << k
        end
      end
    end
    return nodes
  end

  def nodes(nodes) 
    nodes.each do |n, id|
      @out << "#{node(n, id)} [label=\"#{label(n)}\", shape=#{shape(n)}]\n"
    end
  end

  def edges(nodes)
    nodes.each do |n, id|
      n.kids.each do |k|
        @out << "#{node(n, id)} -> #{node(k, nodes[k])}\n"
      end
    end
  end

  def node(n, id)
    "node_#{id}"
  end

  def label(n)
    if n.is_a?(Leaf) then
      n.value.gsub(/"/, '\\"').gsub(/\n/, "\\n")
    elsif n.is_a?(Node) then
      n.type.to_s
    elsif n.is_a?(Pack) then
      ''
    end
  end

  def shape(n)
    if n.is_a?(Leaf) then
      'plaintext'
    elsif n.is_a?(Node) then
      if n.kids.length > 1 then
        'diamond'
      else
        'box'
      end
    elsif n.is_a?(Pack) then
      'point'
    elsif n.is_a?(Empty)
      'none'
    else
      raise "Unsupported node!"
    end
  end

end

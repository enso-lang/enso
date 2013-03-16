
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
      if node.Pack? then
        if node.left then
          if !nodes[node.left] then
            nodes[node.left] = id += 1
            todo << node.left
          end
        end
        if !nodes[node.right] then
          nodes[node.right] = id += 1
          todo << node.right
        end
      else
        nodes[node] = id += 1
        node.kids.each do |k|
          if !nodes[k] then
            nodes[k] = id += 1
            todo << k
          end
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
    label_(n).gsub(/"/, '\\"').gsub("\n", '\\n')
  end

  def label_(n)
    if n.Leaf? then
      n.value.to_s + " (#{n.starts}, #{n.ends})"
    elsif n.Node? then
      if n.type.schema_class.name == 'Rule' 
        "rule #{n.type.name}" + " (#{n.starts}, #{n.ends})"
      elsif n.type.schema_class.name == 'Create'
        "[#{n.type.name}]" + " (#{n.starts}, #{n.ends})"
      elsif n.type.schema_class.name == 'Field'
        "#{n.type.name}:" + " (#{n.starts}, #{n.ends})"
      elsif n.type.schema_class.name == 'Call'
        "call #{n.type.rule.name}" + " (#{n.starts}, #{n.ends})"
      elsif n.type.schema_class.name == 'Item'
        "item #{n.type.expression}" + " (#{n.starts}, #{n.ends})"
      else
        n.type.to_s + " (#{n.starts}, #{n.ends})"
      end
    elsif n.Pack? then
      "#{n.pivot}, #{n.type}"
    end
  end

  def shape(n)
    if n.Leaf? then
      'plaintext'
    elsif n.Node? then
      if n.kids.size > 1 then
        'diamond'
      else
        'box'
      end
    elsif n.Pack? then
      'ellipse'
    elsif n.Empty? then
      'none'
    else
      raise "Unsupported node!"
    end
  end

end

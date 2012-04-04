

require 'core/system/load/load'

class SpineToDot

  def initialize
    @nodes = []
    @edges = []
  end
  

  def todot(obj, out = '')
    out << "digraph #{obj.schema_class.name} {\n"
    out << "graph [ordering=out]\n"
    out << "node [shape=plaintext]\n"
    obj2dot(obj)
    out << (@nodes + @edges).join("\n")
    out << "\n}"
    return out
  end

  def obj2dot(obj)
    prims = []
    obj.schema_class.all_fields.each do |fld|
      next if fld.computed
      if fld.type.Primitive? then
        label = obj[fld.name].inspect.gsub('>', '&gt;').gsub('<', '&lt;').gsub('&', '&amp;')
        label.gsub!(/"/, "\\\"")
        n = node(obj) + "_#{fld.name} [label=\"#{label}\"]"
        @nodes.unshift(n)
        @edges << "#{node(obj)} -> #{n} [label=\"#{fld.name}\"]"
      else
        next unless fld.traversal
        if fld.many then
          next if obj[fld.name].empty?
          from = "coll#{obj[fld.name].object_id}"
          @nodes.unshift("#{from} [shape=point,label=\"\"]")
          edge = "#{node(obj)} -> #{from} [dir=both,label="
          edge << "\"#{fld.name}\","
          edge << "arrowtail=diamond,arrowhead=none]"
          obj[fld.name].each do |trg|
            to = obj2dot(trg)
            @edges << "#{from} -> #{to} [arrowhead=none]"
          end
          @edges << "#{node(obj)} -> #{from} [label=\"#{fld.name}\"]"
        else
          next if obj[fld.name].nil?
          from = node(obj)
          to = obj2dot(obj[fld.name])
          edge = "#{from} -> #{to} [dir=both,"
          edge << "arrowtail=diamond,arrowhead=none,"
          edge << "label=\"#{fld.name}\""
          edge << "]"
          @edges << edge
        end
      end
    end
    head = obj.schema_class.name #  "#{obj._id}:#{obj.schema_class.name}"
    @nodes.unshift("#{node(obj)} [shape=Mrecord,label=\"#{head}\"]")
    node(obj)
  end

  def node(obj)
    "n#{obj._id}"
  end
end


if __FILE__ == $0 then
  #x = Loader.load('door.state_machine')
  x = Loader.load(ARGV[0])
  t = SpineToDot.new
  t.todot(x, $stdout)
end

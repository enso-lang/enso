

require 'core/system/load/load'

class Todot

  def initialize
    @memo = {}
    @ememo = {}
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
    if @memo[obj] then
      return @memo[obj]
    end
    @memo[obj] = node(obj)
    prims = []
    obj.schema_class.all_fields.each do |fld|
      next if fld.computed
      if fld.type.Primitive? then
        label = obj[fld.name].inspect.gsub('>', '&gt;').gsub('<', '&lt;').gsub('&', '&amp;')
        prims << "<TR><TD>#{fld.name}:</TD><TD>#{label}</TD></TR>\n"
      else
        if fld.inverse && @ememo[fld.inverse] then
          next
        end
        @ememo[fld] = true
        
        if fld.many then
          next if obj[fld.name].empty?
          from = "coll#{obj[fld.name].object_id}"
          @nodes << "#{from} [shape=point,label=\"\"]"
          edge = "#{node(obj)} -> #{from} [dir=both,label="
          if fld.inverse then
            edge << "\"#{fld.name}/#{fld.inverse.name}\","
          else
            edge << "\"#{fld.name}\","
          end
          if fld.traversal then
            edge << "arrowtail=diamond,arrowhead=none]"
          else
            edge << "arrowtail=none,arrowhead=normal]"
          end
          @edges << edge
          obj[fld.name].each do |trg|
            to = obj2dot(trg)
            @edges << "#{from} -> #{to} [arrowhead=none]"
          end
        else
          next if obj[fld.name].nil?
          from = node(obj)
          to = obj2dot(obj[fld.name])
          edge = "#{from} -> #{to} [dir=both,"
          if fld.traversal then
            if fld.inverse then
              edge << "arrowtail=diamond,arrowhead=normal,"
            else
              edge << "arrowtail=diamond,arrowhead=none,"
            end
          else
            if fld.inverse
              edge << "arrowtail=normal,arrowhead=normal,"
            else
              edge << "arrowtail=none,arrowhead=normal,"
            end
          end
          if fld.inverse then
            edge << "label=\"#{fld.name}/#{fld.inverse.name}\""
          else
            edge << "label=\"#{fld.name}\""
          end
          edge << "]"
          @edges << edge
        end
      end
    end
    head = "<TR><TD COLSPAN=\"2\" ALIGN=\"CENTER\"><U>#{obj._id}:#{obj.schema_class.name}</U></TD></TR>"
    @nodes.unshift("#{node(obj)} [label=<<TABLE STYLE=\"ROUNDED\" CELLBORDER=\"0\">#{head}#{prims.join}</TABLE>>]")
    node(obj)
  end

  def node(obj)
    "n#{obj._id}"
  end
end


if __FILE__ == $0 then
  #x = Loader.load('door.state_machine')
  x = Loader.load(ARGV[0])
  t = Todot.new
  t.todot(x, $stdout)
end

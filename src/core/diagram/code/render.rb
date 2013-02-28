require 'core/expr/code/render'

module Render

  module RenderStencil
    include Interpreter::Dispatcher
    include Render::RenderExpr

    def render_Stencil(title, root, body)
      %{
<!DOCTYPE html>
<html>
<head>
<script src="./jquery-1.9.1.min.js">
</script>
<title>} + title.to_s + %{</title>
</head>
<body>
      } + body.inject(""){|memo, obj|memo+render(obj)} + %{
</body>
</html>
      }
    end

    def render_Container(label, props, direction, items)
      res = "<table>\n"
      res += "<tr>" if direction==2
      res += items.inject("") do |memo,item|
        if direction==1  #vertical
          memo + "<tr><td>" + render(item) + "</td></tr>\n"
        elsif direction==2  #horizontal
          memo + "<td>" + render(item) + "</td>"
        end
      end
      res += "</tr>" if direction==2
      res += "</table>\n"
      res
    end

    def render_Shape(label, props, kind, content)
      render(content)
    end

    def render_Text(label, props, string, editable)
      render(string)
    end

    def render_TextBox(label, props, value)
      %/<input type="text" name="" value="#{render(value)}">/
    end
    
    def render_Pages(label, props, items, current)
      index = if current and current.val.is_a? Integer
        current.val
      else
        0
      end
      raise "Trying to render an out of bounds page" if index >= items.length
      render(items[index])
    end

    def render_?(fields, type, args)
      ""
    end
  end

  class RenderStencilC
    include RenderStencil
    def initialize
    end
  end

  def self.render(obj, *args)
    interp = RenderStencilC.new
    if args.empty?
      interp.render(obj)
    else
      interp.dynamic_bind *args do
        interp.render(obj)
      end
    end
  end
end

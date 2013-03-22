require 'core/expr/code/renderexp'
require 'core/diagram/code/construct'
require 'core/semantics/code/interpreter'

module Render

  module RenderStencil
    include Interpreter::Dispatcher
    include Renderexp::RenderExpr

    def render_Stencil(obj)
      pre = %{
<!DOCTYPE html>
<html>
<head>
<script src="./lib/jquery-1.9.1.min.js">
</script>
<title>} + obj.title + %{</title>
</head>
<body>
      } 
      post = %{
</body>
</html>
      }
      body = dynamic_bind env: {"data"=>@D[:data]} do 
        render(obj.body) 
      end
      pre + body + post
    end

    def render_Container(obj)
      res = "<table>\n"
      res += "<tr>" if obj.direction==2
      obj.items.each do |item|
        if obj.direction==1  #vertical
          res += "<tr><td>" + render(item) + "</td></tr>\n"
        elsif obj.direction==2  #horizontal
          res += "<td>" + render(item) + "</td>"
        end
      end
      res += "</tr>" if obj.direction==2
      res += "</table>\n"
      res
    end

    def render_Shape(obj)
      render(obj.content)
    end

    def render_Text(obj)
      render(obj.string)
    end

    def render_TextBox(obj)
      %/<input type="text" name="" value="#{render(obj.value)}">/
    end
    
    def render_Pages(obj)
      index = Construct::eval(obj.current, env: @D[:env])
      raise "Trying to render an out of bounds page" if index >= obj.items.size
      render(obj.items[index])
    end

    def render_?(obj)
      ""
    end
  end

  class RenderStencilC
    include RenderStencil
  end

  def self.render(obj, args={})
    interp = RenderStencilC.new
    interp.dynamic_bind args do
      interp.render(obj)
    end
  end
end

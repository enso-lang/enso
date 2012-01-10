#require 'core/grammar/render/layout'
require 'core/expr/code/render'
require 'core/expr/code/dispatch'

class Render
  include Dispatch1
  include RenderExpr
end

def Layout(obj)
  send("Layout_#{obj.schema_class.name}", obj)
end

def Layout_Assign(obj)
  "Set #{Layout_Expr(obj.var)} to #{Layout_Expr(obj.val)}"
end

def Layout_TurnSplitter(obj)
  "Turn splitter #{obj.splitter} #{obj.percent==0 ? "left" : obj.percent==0.5 ? "center" : "right"}"
end

def Layout_Expr(obj)
  Render.new.render(obj)
end

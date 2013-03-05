
module Render
  module RenderExpr
    
    include Interpreter::Dispatcher    
      
    def render(obj)
      dispatch(:render, obj)
    end
  
    def render_EBinOp(op, e1, e2)
      "#{render(e1)} #{op} #{render(e2)}"
    end
  
    def render_EUnOp(op, e)
      "#{op} #{render(e)}"
    end
  
    def render_EField(e, fname)
      "#{render(e)}.#{fname}"
    end
  
    def render_EVar(name)
      "#{name}"
    end
  
    def render_EConst(val)
      "#{val}"
    end
    
    def render_ENil
      ""
    end
  end
  
  class RenderExprC
    include RenderExpr
    def initialize
    end
  end
end

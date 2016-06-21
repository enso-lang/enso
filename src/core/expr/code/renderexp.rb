require 'core/semantics/code/interpreter'

module Renderexp
  module RenderExpr
    
    include Interpreter::Dispatcher    
      
    def render(obj)
      dispatch_obj(:render, obj)
    end
  
    def render_EBinOp(obj)
      "#{render(obj.e1)} #{obj.op} #{render(obj.e2)}"
    end
  
    def render_EUnOp(obj)
      "#{obj.op} #{render(obj.e)}"
    end
  
    def render_EField(obj)
      "#{render(obj.e)}.#{obj.fname}"
    end
  
    def render_ESubscript(obj)
      "#{render(obj.e)}[#{render(obj.sub)}]"
    end
  
    def render_EVar(obj)
      "#{obj.name}"
    end
  
    def render_EConst(obj)
      "#{obj.val}"
    end
    
    def render_ENil
      ""
    end
  end
  
  class RenderExprC
    include RenderExpr
  end

  def self.render(obj, args={})
    interp = RenderExprC.new
    interp.dynamic_bind(args) do
      interp.render(obj)
    end
  end
end

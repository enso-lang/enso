
module Render
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

  def self.eval(obj, args={})
    interp = EvalExprC.new
    interp.dynamic_bind args do
      interp.eval(obj)
    end
  end
end

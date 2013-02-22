require 'core/expr/code/render'
require 'core/semantics/code/interpreter'
require 'core/diff/code/equals'
require 'core/grammar/render/layout'

def Layout(obj)
  if respond_to? "Layout_#{obj.schema_class.name}"
    send("Layout_#{obj.schema_class.name}", obj)
  else
    send("Layout_Expr", obj)
  end
end

def Layout_Assign(obj)
  if obj.val.EBinOp? and ['+','-'].include?(obj.val.op) and Equals.equals(obj.var,obj.val.e1)
    "#{case obj.val.op
      when '+'
        "Raise"
      when '-'
        "Lower"
    end} #{Layout(obj.var)} by #{Layout(obj.val.e2)}"
  else
    "Set #{Layout(obj.var)} to #{Layout(obj.val)}"
  end
end

def Layout_Global(obj)
  Layout(obj.var)
end

def Layout_TurnSplitter(obj)
  "Turn splitter #{obj.splitter} #{obj.percent==0 ? "left" : obj.percent==0.5 ? "center" : "right"}"
end

def Layout_Expr(obj)
  begin
    Interpreter(RenderExpr).render(obj)
  rescue
    ""
  end
end

def CheckConnect(src, trans)
  tgt = trans.target
  if tgt.transitions.detect {|trans| trans.target == src}
    if tgt.name < src.name
      0
    else
      2
    end
  else
    1
  end
end

def getCurrState
  $st.controller.current
end


require 'core/expr/code/render'
require 'core/semantics/code/interpreter'
require 'core/diff/code/equals'

def Layout(obj)
  send("Layout_#{obj.schema_class.name}", obj)
end

def Layout_Assign(obj)
  if obj.val.EBinOp? and ['+','-'].include?(obj.val.op) and Equals.equals(obj.var,obj.val.e1)
    "#{case obj.val.op
      when '+'
        "Raise"
      when '-'
        "Lower"
    end} #{Layout_Expr(obj.var)} by #{Layout_Expr(obj.val.e2)}"
  else
    "Set #{Layout_Expr(obj.var)} to #{Layout_Expr(obj.val)}"
  end
end

def Layout_TurnSplitter(obj)
  "Turn splitter #{obj.splitter} #{obj.percent==0 ? "left" : obj.percent==0.5 ? "center" : "right"}"
end

def Layout_Expr(obj)
  Interpreter(RenderExpr).render(obj)
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

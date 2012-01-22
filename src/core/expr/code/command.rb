
module Command

  def eval_EWhile(cond, body, args=nil)

  end

  def eval_EFor(op, e, args=nil)
  end

  def eval_EIf(e, fname, args=nil)
  end

  def eval_ESwitch(name, args=nil)
  end

  def eval_EBlock(val, args=nil)
  end

  def eval_EFunDef(val, args=nil)
  end

  def eval_EAssign(val, args=nil)
  end

  def eval_EImport(val, args=nil)
  end

  EWhile ::= [EWhile] "while" cond:Expr body:Command
  EFor ::= [EFor] "for" var:str "=" list:Expr body:Command
  EIf ::= [EIf] "if" cond:Expr body:Command "else" else:Command
  ESwitch ::= [ESwitch] "switch" e:Expr
  EBlock ::= [EBlock] "{" body:Command* "}"
  EFunDef ::= [EFunDef] "def" name:str "(" params:{Param,","}* ")" body:Command
  EAssign ::= [EAssign] var:Expr "=" val:Expr
  EImport ::= [EImport] "require" path:str

end

package Expr
import schema.*
open class ExprImp : Expr, CommandImp {
  constructor(
  ) : super()
}
open class CommandImp : Command {
  constructor(
  )
}
open class EWhileImp : EWhile, CommandImp {
  constructor(
    cond : Expr,
    body : Command
  ) : super() {
    this.cond = cond
    this.body = body
  }
  override var cond : Expr
  override var body : Command
}
open class EForImp : EFor, CommandImp {
  constructor(
    varx : String,
    list : Expr,
    body : Command
  ) : super() {
    this.varx = varx
    this.list = list
    this.body = body
  }
  override var varx : String
  override var list : Expr
  override var body : Command
}
open class EIfImp : EIf, CommandImp {
  constructor(
    cond : Expr,
    body : Command,
    body2 : Command? = null
  ) : super() {
    this.cond = cond
    this.body = body
    this.body2 = body2
  }
  override var cond : Expr
  override var body : Command
  override var body2 : Command?
}
open class EBlockImp : EBlock, CommandImp {
  constructor(
  ) : super() {
  }
  override val fundefs = ArrayList<EFunDef> ()
  override val body = ArrayList<Command> ()
}
open class EFunDefImp : EFunDef {
  constructor(
    name : String,
    body : Command
  ) {
    this.name = name
    this.body = body
  }
  override var name : String
  override val formals = ArrayList<Formal> ()
  override var body : Command
}
open class EAssignImp : EAssign, CommandImp {
  constructor(
    varx : Expr,
    value : Expr
  ) : super() {
    this.varx = varx
    this.value = value
  }
  override var varx : Expr
  override var value : Expr
}
open class EImportImp : EImport, CommandImp {
  constructor(
    path : String
  ) : super() {
    this.path = path
  }
  override var path : String
}
open class ETernOpImp : ETernOp, ExprImp {
  constructor(
    op1 : String,
    op2 : String,
    e1 : Expr,
    e2 : Expr,
    e3 : Expr
  ) : super() {
    this.op1 = op1
    this.op2 = op2
    this.e1 = e1
    this.e2 = e2
    this.e3 = e3
  }
  override var op1 : String
  override var op2 : String
  override var e1 : Expr
  override var e2 : Expr
  override var e3 : Expr
}
open class EBinOpImp : EBinOp, ExprImp {
  constructor(
    op : String,
    e1 : Expr,
    e2 : Expr
  ) : super() {
    this.op = op
    this.e1 = e1
    this.e2 = e2
  }
  override var op : String
  override var e1 : Expr
  override var e2 : Expr
}
open class EUnOpImp : EUnOp, ExprImp {
  constructor(
    op : String,
    e : Expr
  ) : super() {
    this.op = op
    this.e = e
  }
  override var op : String
  override var e : Expr
}
open class InstanceOfImp : InstanceOf, ExprImp {
  constructor(
    base : Expr,
    class_name : String
  ) : super() {
    this.base = base
    this.class_name = class_name
  }
  override var base : Expr
  override var class_name : String
}
open class EFunCallImp : EFunCall, ExprImp {
  constructor(
    function : Expr,
    lambda : ELambda? = null
  ) : super() {
    this.function = function
    this.lambda = lambda
  }
  override var function : Expr
  override val params = ArrayList<Expr> ()
  override var lambda : ELambda?
}
open class ELambdaImp : ELambda {
  constructor(
    body : Expr
  ) {
    this.body = body
  }
  override var body : Expr
  override val formals = ArrayList<Formal> ()
}
open class FormalImp : Formal {
  constructor(
    name : String
  ) {
    this.name = name
  }
  override var name : String
}
open class EFieldImp : EField, ExprImp {
  constructor(
    e : Expr,
    fname : String
  ) : super() {
    this.e = e
    this.fname = fname
  }
  override var e : Expr
  override var fname : String
}
open class EVarImp : EVar, ExprImp {
  constructor(
    name : String
  ) : super() {
    this.name = name
  }
  override var name : String
}
open class ESubscriptImp : ESubscript, ExprImp {
  constructor(
    e : Expr,
    sub : Expr
  ) : super() {
    this.e = e
    this.sub = sub
  }
  override var e : Expr
  override var sub : Expr
}
open class EListImp : EList, ExprImp {
  constructor(
  ) : super() {
  }
  override val elems = ArrayList<Expr> ()
}
open class ENewImp : ENew, ExprImp {
  constructor(
    cls : String
  ) : super() {
    this.cls = cls
  }
  override var cls : String
}
open class EConstImp : EConst, ExprImp {
  constructor(
  ) : super()
}
open class EStrConstImp : EStrConst, EConstImp {
  constructor(
    value : String
  ) : super() {
    this.value = value
  }
  override var value : String
  override val type : String by lazy {
    "str"
  }
}
open class EIntConstImp : EIntConst, EConstImp {
  constructor(
    value : Int = 0
  ) : super() {
    this.value = value
  }
  override var value : Int
  override val type : String by lazy {
    "int"
  }
}
open class EBoolConstImp : EBoolConst, EConstImp {
  constructor(
    value : Boolean = false
  ) : super() {
    this.value = value
  }
  override var value : Boolean
  override val type : String by lazy {
    "bool"
  }
}
open class ERealConstImp : ERealConst, EConstImp {
  constructor(
    value : Float = 0.0F
  ) : super() {
    this.value = value
  }
  override var value : Float
  override val type : String by lazy {
    "real"
  }
}
open class ENilImp : ENil, EConstImp {
  constructor(
  ) : super()
}

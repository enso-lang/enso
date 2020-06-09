package Command
import schema.*
open class CommandImp : Command {
  constructor(
  )
}
open class ExprImp : Expr, CommandImp {
  constructor(
  ) : super()
}
open class StencilImp : Stencil {
  constructor(
    title : String?,
    root : String,
    body : Command
  ) {
    this.title = title
    this.root = root
    this.body = body
  }
  override var title : String?
  override var root : String
  override var body : Command
}
open class PartImp : Part, CommandImp {
  constructor(
  ) : super() {
  }
  override val props = ArrayList<Assign> ()
}
open class AssignImp : Assign {
  constructor(
    loc : Expr,
    exp : Expr
  ) {
    this.loc = loc
    this.exp = exp
  }
  override var loc : Expr
  override var exp : Expr
}
open class LabelImp : Label, PartImp {
  constructor(
    label : Expr,
    body : Command
  ) : super() {
    this.label = label
    this.body = body
  }
  override var label : Expr
  override var body : Command
}
open class ColorImp : Color, ExprImp {
  constructor(
    r : Expr,
    g : Expr,
    b : Expr
  ) : super() {
    this.r = r
    this.g = g
    this.b = b
  }
  override var r : Expr
  override var g : Expr
  override var b : Expr
}
open class ContainerImp : Container, PartImp {
  constructor(
    direction : Int = 0
  ) : super() {
    this.direction = direction
  }
  override var direction : Int
  override val items = ArrayList<Command> ()
}
open class PageImp : Page, PartImp {
  constructor(
    name : String,
    part : Command
  ) : super() {
    this.name = name
    this.part = part
  }
  override var name : String
  override var part : Command
}
open class TextImp : Text, PartImp {
  constructor(
    string : Expr,
    editable : Boolean = false
  ) : super() {
    this.string = string
    this.editable = editable
  }
  override var string : Expr
  override var editable : Boolean
}
open class ShapeImp : Shape, PartImp {
  constructor(
    kind : String,
    content : Command? = null
  ) : super() {
    this.kind = kind
    this.content = content
  }
  override var kind : String
  override var content : Command?
}
open class ConnectorImp : Connector, PartImp {
  constructor(
  ) : super() {
  }
  override val ends = ArrayList<ConnectorEnd> ()
}
open class ConnectorEndImp : ConnectorEnd {
  constructor(
    arrow : String?,
    label : Expr? = null,
    part : Expr
  ) {
    this.arrow = arrow
    this.label = label
    this.part = part
  }
  override var arrow : String?
  override var label : Expr?
  override var part : Expr
}
open class EAssignImp : EAssign, CommandImp {
  constructor(
    varx : Expr,
    value : Expr,
    body : Command
  ) : super() {
    this.varx = varx
    this.value = value
    this.body = body
  }
  override var varx : Expr
  override var value : Expr
  override var body : Command
}
open class EForImp : EFor, CommandImp {
  constructor(
    index : String?,
    label : String?,
    varx : String,
    list : Expr,
    body : Command
  ) : super() {
    this.index = index
    this.label = label
    this.varx = varx
    this.list = list
    this.body = body
  }
  override var index : String?
  override var label : String?
  override var varx : String
  override var list : Expr
  override var body : Command
}
open class GridImp : Grid, PartImp {
  constructor(
  ) : super() {
  }
  override val axes = ArrayList<AxisData> ()
}
open class AxisDataImp : AxisData {
  constructor(
    direction : String,
    source : Command
  ) {
    this.direction = direction
    this.source = source
  }
  override var direction : String
  override var source : Command
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

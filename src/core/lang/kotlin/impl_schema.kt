package Expr
import schema.Many
interface Expr : Command
interface Command
interface EWhile : Command {
  var cond : Expr
  var body : Command
}
interface EFor : Command {
  var varx : String
  var list : Expr
  var body : Command
}
interface EIf : Command {
  var cond : Expr
  var body : Command
  var body2 : Command?
}
interface EBlock : Command {
  val fundefs : Many<EFunDef>
  val body : Many<Command>
}
interface EFunDef {
  var name : String
  val formals : Many<Formal>
  var body : Command
}
interface EAssign : Command {
  var varx : Expr
  var value : Expr
}
interface EImport : Command {
  var path : String
}
interface ETernOp : Expr {
  var op1 : String
  var op2 : String
  var e1 : Expr
  var e2 : Expr
  var e3 : Expr
}
interface EBinOp : Expr {
  var op : String
  var e1 : Expr
  var e2 : Expr
}
interface EUnOp : Expr {
  var op : String
  var e : Expr
}
interface InstanceOf : Expr {
  var base : Expr
  var class_name : String
}
interface EFunCall : Expr {
  var function : Expr
  val params : Many<Expr>
  var lambda : ELambda?
}
interface ELambda {
  var body : Expr
  val formals : Many<Formal>
}
interface Formal {
  var name : String
}
interface EField : Expr {
  var e : Expr
  var fname : String
}
interface EVar : Expr {
  var name : String
}
interface ESubscript : Expr {
  var e : Expr
  var sub : Expr
}
interface EList : Expr {
  val elems : Many<Expr>
}
interface ENew : Expr {
  var cls : String
}
interface EConst : Expr
interface EStrConst : EConst {
  var value : String
  val type : String
}
interface EIntConst : EConst {
  var value : Int
  val type : String
}
interface EBoolConst : EConst {
  var value : Boolean
  val type : String
}
interface ERealConst : EConst {
  var value : Float
  val type : String
}
interface ENil : EConst

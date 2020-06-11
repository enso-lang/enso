package Grammar
import schema.Many
interface Grammar {
  var start : Rule
  val rules : Map<String, Rule>
}
interface Pattern
interface Rule {
  var name : String
  var grammar : Grammar
  var arg : Pattern?
}
interface Alt : Pattern {
  val alts : Many<Pattern>
}
interface Sequence : Pattern {
  val elements : Many<Pattern>
}
interface Create : Pattern {
  var name : String
  var arg : Pattern
}
interface Field : Pattern {
  var name : String
  var arg : Pattern
}
interface Terminal : Pattern
interface Value : Terminal {
  var kind : String
}
interface Ref : Terminal {
  var path : Expr
}
interface Lit : Terminal {
  var value : String
}
interface Call : Pattern {
  var rule : Rule
}
interface Regular : Pattern {
  var arg : Pattern
  var optional : Boolean
  var many : Boolean
  var sep : Pattern?
}
interface NoSpace : Pattern
interface Break : Pattern {
  var lines : Int
}
interface Indent : Pattern {
  var indent : Int
}
interface Hide : Pattern {
  var arg : Pattern
}
interface Code : Terminal {
  var expr : Expr
}
interface Expr
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

package Schema
import schema.Many
interface Schema {
  val types : Many<Type>
  val classes : List<Class>
  val primitives : List<Primitive>
}
interface Type {
  var name : String
  var schema : Schema
  val key : Field?
}
interface Primitive : Type
interface Class : Type {
  val supers : Many<Class>
  val subclasses : Many<Class>
  val defined_fields : Many<Field>
  val key : Field?
  val fields : List<Field>
  val all_fields : List<Field>
}
interface Field {
  var name : String
  var owner : Class
  var type : Type
  var optional : Boolean
  var many : Boolean
  var key : Boolean
  var inverse : Field?
  var computed : Expr?
  var traversal : Boolean
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
interface EAddress : Expr {
  var e : Expr
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

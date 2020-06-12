package Schema
import schema.*
open class SchemaImp : Schema {
  constructor(
  ) {
  }
  override val types = KeyedMany(this, Type::schema)
  override val classes : List<Class> by lazy {
    types.select() { (t)-> t is Class }
  }
  override val primitives : List<Primitive> by lazy {
    types.select() { (t)-> t is Primitive }
  }
}
open class TypeImp : Type {
  constructor(
    name : String,
    schema : Schema
  ) {
    this.name = name
    this.schema = schema
  }
  override var name : String
  override var schema : Schema by OneMany(Schema::types)
  override val key : Field? by lazy {
    null
  }
}
open class PrimitiveImp : Primitive, TypeImp {
  constructor(
    name : String,
    schema : Schema
  ) : super(name, schema)
}
open class ClassImp : Class, TypeImp {
  constructor(
    name : String,
    schema : Schema
  ) : super(name, schema) {
  }
  override val supers = ManyMany(this, Class::subclasses)
  override val subclasses = ManyMany(this, Class::supers)
  override val defined_fields = KeyedMany(this, Field::owner)
  override val key : Field? by lazy {
    fields.find() { (f)-> f.key }
  }
  override val fields : List<Field> by lazy {
    all_fields.select() { (f)-> not f.computed }
  }
  override val all_fields : List<Field> by lazy {
    (supers.flat_map() { (s)-> s.all_fields }).union(defined_fields)
  }
}
open class FieldImp : Field {
  constructor(
    name : String,
    owner : Class,
    type : Type,
    optional : Boolean = false,
    many : Boolean = false,
    key : Boolean = false,
    inverse : Field? = null,
    computed : Expr? = null,
    traversal : Boolean = false
  ) {
    this.name = name
    this.owner = owner
    this.type = type
    this.optional = optional
    this.many = many
    this.key = key
    this.inverse = inverse
    this.computed = computed
    this.traversal = traversal
  }
  override var name : String
  override var owner : Class by OneMany(Class::defined_fields)
  override var type : Type
  override var optional : Boolean
  override var many : Boolean
  override var key : Boolean
  override var inverse : Field? by OneOne(Field::inverse)
  override var computed : Expr?
  override var traversal : Boolean
}
open class ExprImp : Expr {
  constructor(
  )
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

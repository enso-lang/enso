package Grammar
import schema.*
open class GrammarImp : Grammar {
  constructor(
    start : Rule
  ) {
    this.start = start
  }
  override var start : Rule
  override val rules = ManyOne(this, Rule::grammar)
}
open class PatternImp : Pattern {
  constructor(
  )
}
open class RuleImp : Rule {
  constructor(
    name : String,
    grammar : Grammar,
    arg : Pattern? = null
  ) {
    this.name = name
    this.grammar = grammar
    this.arg = arg
  }
  override var name : String
  override var grammar : Grammar by OneMany(Grammar::rules)
  override var arg : Pattern?
}
open class AltImp : Alt, PatternImp {
  constructor(
  ) : super() {
  }
  override val alts = ArrayList<Pattern> ()
}
open class SequenceImp : Sequence, PatternImp {
  constructor(
  ) : super() {
  }
  override val elements = ArrayList<Pattern> ()
}
open class CreateImp : Create, PatternImp {
  constructor(
    name : String,
    arg : Pattern
  ) : super() {
    this.name = name
    this.arg = arg
  }
  override var name : String
  override var arg : Pattern
}
open class FieldImp : Field, PatternImp {
  constructor(
    name : String,
    arg : Pattern
  ) : super() {
    this.name = name
    this.arg = arg
  }
  override var name : String
  override var arg : Pattern
}
open class TerminalImp : Terminal, PatternImp {
  constructor(
  ) : super()
}
open class ValueImp : Value, TerminalImp {
  constructor(
    kind : String
  ) : super() {
    this.kind = kind
  }
  override var kind : String
}
open class RefImp : Ref, TerminalImp {
  constructor(
    path : Expr
  ) : super() {
    this.path = path
  }
  override var path : Expr
}
open class LitImp : Lit, TerminalImp {
  constructor(
    value : String
  ) : super() {
    this.value = value
  }
  override var value : String
}
open class CallImp : Call, PatternImp {
  constructor(
    rule : Rule
  ) : super() {
    this.rule = rule
  }
  override var rule : Rule
}
open class RegularImp : Regular, PatternImp {
  constructor(
    arg : Pattern,
    optional : Boolean = false,
    many : Boolean = false,
    sep : Pattern? = null
  ) : super() {
    this.arg = arg
    this.optional = optional
    this.many = many
    this.sep = sep
  }
  override var arg : Pattern
  override var optional : Boolean
  override var many : Boolean
  override var sep : Pattern?
}
open class NoSpaceImp : NoSpace, PatternImp {
  constructor(
  ) : super()
}
open class BreakImp : Break, PatternImp {
  constructor(
    lines : Int = 0
  ) : super() {
    this.lines = lines
  }
  override var lines : Int
}
open class IndentImp : Indent, PatternImp {
  constructor(
    indent : Int = 0
  ) : super() {
    this.indent = indent
  }
  override var indent : Int
}
open class HideImp : Hide, PatternImp {
  constructor(
    arg : Pattern
  ) : super() {
    this.arg = arg
  }
  override var arg : Pattern
}
open class CodeImp : Code, TerminalImp {
  constructor(
    expr : Expr
  ) : super() {
    this.expr = expr
  }
  override var expr : Expr
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
open class EAddressImp : EAddress, ExprImp {
  constructor(
    e : Expr
  ) : super() {
    this.e = e
  }
  override var e : Expr
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

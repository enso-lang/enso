module rsc::core::grammar::models::ExprGrammar

extend rsc::core::grammar::models::Lexical;

start syntax Expr
  = ETernOp
  ;
  
syntax ETernOp
  = eTernOp: ETernOp e1 "?" EOr e2 ":" EOr e3
  | EOr
  ;

syntax EOr
  = eBinOp: EOr e1 "or" EAnd e2
  | EAnd
  ;  

syntax EAnd
  = eBinOp: EAnd e1 "and" EBinOp1 e2
  | EBinOp1
  ;  

syntax EBinOp1
  = eBinOp: EBinOp1 e1 BinOp1 op EBinOp2
  | EBinOp2
  ;
  
syntax BinOp1
  = eq: "=="
  | neq: "!="
  | gt: "\<"
  | lt: "\>"
  | leq: "\<="
  | geq: "\>="
  ;

syntax EBinOp2
  = eBinOp: EBinOp2 e1 BinOp2 op EBinOp3 e2
  | EBinOp3
  ;
  
syntax BinOp2
  = add: "+"
  | sub: "-"
  ;

syntax EBinOp3
  = eBinOp: EBinOp3 e1 BinOp3 op EUnOp e2
  | EUnOp
  ;
  
syntax BinOp3
  = mul: "*"
  | div: "/"
  | \mod: "%"
  ;

syntax EUnOp
  = eUnOp: "not" Expr e
  | EFunCall
  | EListComp
  | Primary
  ;

syntax EFunCall
  = eFunCall: EUnOp fun "(" {Expr ","}* params ")"
  ;

syntax Primary
  = EConst
  | eField: Primary e "." Sym fname
  | eSubscript: Expr e "[" Expr sub "]"
  | eVar: Sym name
  | eList: "[" {Expr ","}* elems "]"
  | bracket "(" Expr ")"
  ;

syntax EListComp
  = eListComp: CompOp op Sym var "in" Expr list ":" Expr e
  ;
  
syntax CompOp
  = \all: "all?"
  | \any: "any?"
  ;

syntax EConst
  = eStrConst: Str val
  | eIntConst: Int val
  | eRealConst: Real val
  | eBoolConst: Bool val
  | eNil: "nil"
  ;
  
syntax Bool
  = \true: "true"
  | \false: "false"
  ;
 
 keyword Reserved 
  = "true"
  | "false"
  | "any"
  | "all"
  | "not"
  | "and"
  | "or"
  ;

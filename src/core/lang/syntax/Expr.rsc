module core::lang::\syntax::Expr

syntax EXPR 
  = primary: PRIMARY
  > not: [a-zA-Z0-9_] !<< "!" EXPR
  | bitNot: "~" EXPR
  | uPlus: "+" !>> [\ \t] EXPR
  > right exp: EXPR "**" EXPR
  > uMin: "-" !>> [\ \t] EXPR
  > left (mul: EXPR "*" EXPR
    | div: EXPR "/" EXPR
    | rem: EXPR "%" EXPR
  )
  > left (add: EXPR "+" EXPR
    | sub: EXPR "-" EXPR
  )
  > right (shleft: EXPR "\<\<" EXPR // right?
    | shright: EXPR "\>\>" EXPR
  )
  > left bitAnd: EXPR "&" EXPR // left?
  > left ( bitOr: EXPR "|" EXPR // left?
    | bitXor: EXPR "^" EXPR
  )
  > non-assoc (gt: EXPR "\>" EXPR // left? they are methods...
    | geq: EXPR "\>=" EXPR
    | lt: EXPR "\<" EXPR
    | leq: EXPR "\<=" EXPR
  )
  > non-assoc (\case: EXPR "\<=\>" EXPR // left?
    | eq: EXPR "==" EXPR
    | eeq: EXPR "===" EXPR
    | neq: EXPR "!=" EXPR
    | match: EXPR "=~" EXPR
    | notMatch: EXPR "!~" EXPR
  )
  > left and: EXPR "&&" EXPR
  > left or: EXPR "||" EXPR
  > non-assoc (range: EXPR ".." EXPR
    | range3: EXPR "..." EXPR
  )
  > triCond: EXPR [a-zA-Z0-9_] !<< "?" EXPR ":" EXPR
  > not2: "not" EXPR
  > left (and2: EXPR "and" EXPR 
    | or2: EXPR "or" EXPR
  )
  > assign: LHS "=" EXPR
  | assign: LHS OP_ASGN EXPR
  // raise "bla" if x ==> raise ("bla" if x) !!!
  > left (ifMod: EXPR "if" EXPR
    | whileMod: EXPR "while" EXPR
    | unlessMod: EXPR "unless" EXPR
    | untilMod: EXPR "until" EXPR
  )
  ;
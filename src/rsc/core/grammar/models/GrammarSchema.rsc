module rsc::core::grammar::models::GrammarSchema

extend rsc::core::grammar::models::PathSchema;

data Grammar
  = grammar(str rule, list[Rule] rules)
  ;

data Rule
  = rule(str name, list[Pattern] arg)
  ;
 
data Pattern
  = alt(Alt alt)
  | sequence(Sequence sequence)
  | create(Create create)
  | field(Field field)
  | code(Code code)
  | \value(Value \value)
  | ref(Ref ref)
  | lit(Lit lit)
  | call(str rule)
  | regular(Regular regular)
  | noSpace(NoSpace noSpace)
  | \break(Break \break)
  | indent(Indent indent)
  ;  
 
data Alt
  = alt(list[Pattern] alts)
  ;

data Sequence
  = sequence(list[Pattern] elements)
  ;

data Create
  = create(str name, Pattern arg)
  ;

data Field
  = field(str name, Pattern arg)
  ;
 

data Code
  = code(Expr expr)
  ;

data Value
  = \value(str kind)
  ;
 
data Ref
  = ref(Path path)
  ;
 
data Lit
  = lit(str \value)
  ;

data Call
  = call(str rule)
  ;

data Regular
  = regular(Pattern arg, bool optional, bool many, list[Pattern] sep)
  ;

data NoSpace
  = noSpace(); 

data Break
  = \break(int lines)
  ;

data Indent
  = indent(int indent)
  ;

// extension
data Key
  = \it(It \it)
  ;

data It
  = \it()
  ;

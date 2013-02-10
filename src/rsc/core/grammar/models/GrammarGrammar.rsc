module rsc::core::grammar::models::GrammarGrammar

extend rsc::core::grammar::models::ExprGrammar;
extend rsc::core::grammar::models::PathGrammar;
extend rsc::core::grammar::models::Lexical;

start syntax Grammar
  = grammar: Import* imports "start" Sym start Rule* rules
  ;
  
syntax Import
  = "import" {Model ","}+
  ;
  
syntax Model
  = model: Sym name "." Sym meta
  ;

syntax Rule
  = rule: Sym name "::=" Alt arg
  | rule: "abstract" Sym name
  ;

syntax Alt
  = alt: {Create "|"}+ alts
  ;

syntax Create
  = create: "[" Sym name "]" Sequence arg
  | Sequence
  ;

syntax Sequence
  = sequence: Field* elements
  ;

syntax Field
  = field: Sym name ":" Pattern arg
  | Pattern
  ;

syntax Pattern
  = intValue: "int"
  | intValue: "str"
  | intValue: "real"
  | intValue: "sym"
  | intValue: "atom"
  | code: "{" Expr expr "}"
  | ref: "\<" Path path "\>"
  | lit: Str value
  | call: Sym rule
  | regularStar: Pattern arg "*" Sep?
  | regularOpt: Pattern arg "?"
  | regularPlus: Pattern arg "+" Sep?
  | noSpace: "."
  | \break: "/" Int? lines
  | indent1: "\>" 
  | indent2: "\<"
  | bracket "(" Alt ")"
  ; 

syntax Sep
  = sep: "@" Pattern sep
  ;    

// extension of path.grammar
syntax Key
  = \it: "it"
  ; 
  
keyword Reserved
  = "it"
  | "start"
  ;


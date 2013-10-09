module core::lang::\syntax::EnsoLanguage

extend core::lang::\syntax::Layout;

/*

To simplify:

- distinguish stmts from expression
- require () everywhere in calls
- don't support do
- don't support destructuring assignment
- require then and do (maybe?)
- disallow return
- allow only statically nested modules
- disallow alias, undef, if/unless etc. modifiers
- remove hash literals

*/ 

/*
Rules

- always write parens in expressions and when invoking blocks, *except* if there are now arguments
- there is no hash literal anymore.
- all keywords in this grammar are reserved. TODO: fix x.class problem.
- there is no do .. end notation (TODO)
*/


start syntax Unit 
  = unit: STMTS
  ;

syntax STMTS
 = stmts: NL* {STMT TERM}+ stmts NL* // possibly this could be simplified.
 | empties: NL*
 ;
 
syntax TERM  = ";" | NL+ ; // need to have plus, otherwise no comments inbetween...

lexical NL
  = [\n] (Comment|[\ \t\n])* !>> [\ \t\n#]
  ;
  
syntax STMT
  = ifThenElse: "if" EXPR THEN STMTS ELSIF* ELSE? "end"
  | unless: "unless" EXPR THEN STMTS ELSE? "end"
  | whileDo: "while" EXPR DO STMTS "end"
  | untilDo: "until" EXPR DO STMTS "end"
  | caseWhen: "case" STMTS WHEN+ ELSE? "end"
  | forIn: "for" BLOCK_VAR "in" EXPR DO STMTS "end"
  | beginRescue: "begin" STMTS RESCUE+ ELSE? ENSURE? "end"
  | class: "class" IDENTIFIER EXTEND? STMTS "end" 
  | \module: "module" IDENTIFIER STMTS "end"
  | defArgs: "def" FNAME "(" ARGLIST ")" STMTS "end"
  | def: "def" FNAME TERM STMTS "end"
  | defSingletonArgs: "def" SINGLETON ("."|"::") FNAMENoReserved "(" ARGLIST ")" STMTS "end"
  | defSingleton: "def" SINGLETON ("."|"::") FNAMENoReserved TERM STMTS "end"
  
  // NB: CALLARGS are not optional here.
  // But still it leads to all kinds of ambiguities
  // maybe only allow primaries in commands and no blocks
  | yield: YIELD1 !>> "("  CALLARGS 
  | selfCall: OPERATION1 !>> "("  CALLARGS 
//  | OPERATION2 !>> "("  CALLARGS  BLOCK
  | superCall: SUPER1  !>> "(" CALLARGS 
  | call: PRIMARY "." OPERATION2 !>> "(" CALLARGS 
  | scopeCall: PRIMARY "::" OPERATION3 !>> "(" CALLARGS 
//  | PRIMARY "." OPERATION4 !>> "(" CALLARGS  BLOCK
//  | PRIMARY "::" OPERATION5 !>> "("  CALLARGS BLOCK
  
  | assign: LHS "=" STMT ! expr
  | assign: LHS OP_ASGN STMT ! expr
  
  | expr: EXPR
  ;
  
// Workaround
syntax OPERATION1 = OPERATION;
syntax OPERATION2 = OPERATIONNoReserved;
syntax OPERATION3 = OPERATIONNoReserved;
syntax OPERATION4 = OPERATION;
syntax OPERATION5 = OPERATION;
syntax OPERATION6 = OPERATION;
syntax YIELD1 = "yield";
syntax SUPER1 = "super";

syntax THEN = then: TERM | "then" | TERM "then" ;
syntax DO   = \do: TERM | "do" | TERM "do" ;
syntax ELSIF = elsif: "elsif" EXPR THEN STMTS;
syntax ELSE = \else: "else" STMTS;
syntax WHEN = \when: "when" WHEN_ARGS THEN STMTS;
syntax RESCUE 
  = rescue: "rescue" {EXPR ","}* DO STMTS
  | rescue: "rescue" EXPR "=\>" EXPR DO STMTS
  ;
  
syntax ENSURE = ensure: "ensure" STMTS;
syntax EXTEND = \extend: "\<" PRIMARY; // should probably be expression

syntax BLOCK
  = block: "{" STMTS "}"
  | block: "{" "|" BLOCK_VAR "|" STMTS "}"
  | block: "do" STMTS "end"
  | block: "do" "|" BLOCK_VAR "|" STMTS "end"  
  ;

syntax PRIMARY
  = group: "(" STMTS ")"
  | literal: LITERAL
  | variable: VARIABLE ! id 
  | nil: "nil"
  | self: "self"
  | \true: "true"
  | \false: "false"
  | moduleIdentifer: [a-zA-Z_0-9] !<< "::" IDENTIFIER
  | array: [a-zA-Z_0-9] !<< "[" {EXPR ","}* "]"
  | yield: "yield" 
  | yield: YIELD2 >> "(" "(" CALLARGS? ")"
  | selfSend: OPERATION
  | selfSend: OPERATION BLOCK
  | selfSend: POPERATION1 >> "(" "(" CALLARGS? ")"
  | selfSend: POPERATION2 >> "(" "(" CALLARGS? ")" BLOCK
  | super: "super"
  | hash: HASH
  | super: SUPER2 >> "(" "(" CALLARGS? ")"
  | subscript: PRIMARY >> "[" "[" {EXPR ","}* "]"
  | send: PRIMARY "." OPERATIONNoReserved 
  | scopeSend: PRIMARY "::" OPERATIONNoReserved
  | send: PRIMARY "." OPERATIONNoReserved BLOCK
  | scopeSend: PRIMARY "::" OPERATIONNoReserved BLOCK
  | send: PRIMARY "." POPERATION3 >> "(" "(" CALLARGS? ")"
  | scopeSend: PRIMARY "::" POPERATION4 >> "(" "(" CALLARGS? ")"
  | send: PRIMARY "." POPERATION5 >> "(" "(" CALLARGS? ")" BLOCK
  | scopeSend: PRIMARY "::" POPERATION6 >> "(" "(" CALLARGS? ")" BLOCK
  ;
  
  
syntax HASH
  = "{" {NameValuePair ","}* "}"
  ;
  
syntax NameValuePair
  = nameValue: IDENTIFIER ":" EXPR;

// Workaround
syntax POPERATION1 = OPERATION;
syntax POPERATION2 = OPERATION;
syntax POPERATION3 = OPERATIONNoReserved;
syntax POPERATION4 = OPERATIONNoReserved;
syntax POPERATION5 = OPERATIONNoReserved;
syntax POPERATION6 = OPERATIONNoReserved;
syntax YIELD2 = "yield";
syntax SUPER2 = "super";


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
  > assign: LHS "=" EXPR
  | assign: LHS OP_ASGN EXPR
  > not2: "not" EXPR
  > left (and2: EXPR "and" EXPR 
    | or2: EXPR "or" EXPR
  )
  > left (ifMod: EXPR "if" EXPR
    | whileMod: EXPR "while" EXPR
    | unlessMod: EXPR "unless" EXPR
    | untilMod: EXPR "until" EXPR
  )
//  | bracket "(" EXPR ")"
;
    
 
lexical OP_ASGN 
  = "+=" | "-=" | "*=" | "/=" | "%=" | "**=" | "&=" | "|=" 
  | "^=" | "\<\<=" | "\>\>=" | "&&=" | "||="
  ;
 
syntax WHEN_ARGS   
  = whenArgs: {EXPR ","}+ 
  | whenArgs: {EXPR ","}+ "," STAR EXPR
  | whenArgs: STAR EXPR
  | whenArgs: /* empty */
  ;

syntax BLOCK_VAR   
  = LHS
  | MLHS
  ;

syntax MLHS
  = MLHS_ITEM "," {MLHS_ITEM ","}+ "," STAR LHS
  | MLHS_ITEM "," {MLHS_ITEM ","}+ 
  | STAR LHS
  | /* empty */
  ;

syntax MLHS_ITEM 
  = LHS
  | "(" MLHS ")"
  ;

syntax LHS 
  = VARIABLE
  | PRIMARY "[" {EXPR ","}* "]"
  | PRIMARY "." IDENTIFIER
;

syntax MRHS 
  = {EXPR ","}+ 
  | {EXPR ","}+ "," STAR EXPR
  | STAR EXPR
  | /* empty */
  ;
  

syntax CALLARGS 
  = {EXPR ","}+ "," KEYWORDS "," SPLAT "," BLOCKARG
  | {EXPR ","}+ "," KEYWORDS "," SPLAT
  | {EXPR ","}+ "," KEYWORDS
  | {EXPR ","}+ "," SPLAT
  | {EXPR ","}+ "," SPLAT "," BLOCKARG
  | {EXPR ","}+ "," BLOCKARG
  | {EXPR ","}+
  | KEYWORDS "," SPLAT "," BLOCKARG
  | KEYWORDS "," SPLAT
  | KEYWORDS
  | SPLAT "," BLOCKARG
  | SPLAT
  | BLOCKARG
  ;
  
syntax KEYWORDS = {KEYWORD ","}+;
syntax SPLAT = STAR EXPR;
syntax BLOCKARG = AMP EXPR;
    
syntax KEYWORD = IDENTIFIER ":" EXPR;

syntax STAR = "*" !>> [\ \t];
syntax AMP = "&" !>> [\ \t];

syntax ARGLIST     
  = {IDENTIFIER ","}+ ","  DEFAULTS "," STAR IDENTIFIER "," AMP IDENTIFIER
  | {IDENTIFIER ","}+ "," DEFAULTS "," STAR IDENTIFIER
  | {IDENTIFIER ","}+ "," DEFAULTS "," AMP IDENTIFIER
  | {IDENTIFIER ","}+ "," DEFAULTS
  | {IDENTIFIER ","}+ "," STAR IDENTIFIER "," AMP IDENTIFIER
  | {IDENTIFIER ","}+ "," STAR IDENTIFIER 
  | {IDENTIFIER ","}+ "," AMP IDENTIFIER
  | {IDENTIFIER ","}+
  | DEFAULTS "," STAR IDENTIFIER "," AMP IDENTIFIER
  | DEFAULTS "," STAR IDENTIFIER
  | DEFAULTS "," AMP IDENTIFIER
  | DEFAULTS
  | STAR IDENTIFIER "," AMP IDENTIFIER
  | STAR IDENTIFIER
  | AMP IDENTIFIER
  | /* empty */
  ;

syntax DEFAULTS
  = {DEFAULT ","}+
  ;
  
syntax DEFAULT
  = IDENTIFIER id "=" EXPR expr
  ;

syntax SINGLETON 
  = VARIABLE
  | "nil"
  | "self" 
  | "(" EXPR ")" ;

syntax LITERAL     
  = Numeric
  | SYMBOL
  | STRING
  | REGEXP
  ;

lexical Numeric
  = [0-9]+ !>> [0-9]
  | [0-9]+ "." [0-9]+ !>> [0-9]
  ;
   
lexical SYMBOL     
  = [:] !<< ":" FNAMENoReserved
  | [:] !<< ":" VARIABLE ! id // use :FNAME instead of :VARIABLE
  ;
    
    
syntax FNAMENoReserved
  = OPERATIONNoReserved
  | IDENTIFIER >> "=" "="
  | ".." | "|" | "^" | "&" | "\<=\>" | "==" | "===" | "=~" | "\>" | "\>=" | "\<" | "\<="
  | "+" | "-" | "*" | "/" | "%" | "**" | "\<\<" | "\>\>" | "~" | "+@" | "-@" | "[]" | "[]="
  ;
    
syntax FNAME
  = OPERATION 
  | IDENTIFIER >> "=" "="
  | ".." | "|" | "^" | "&" | "\<=\>" | "==" | "===" | "=~" | "\>" | "\>=" | "\<" | "\<="
  | "+" | "-" | "*" | "/" | "%" | "**" | "\<\<" | "\>\>" | "~" | "+@" | "-@" | "[]" | "[]="
  ;
              

lexical OPERATION 
  = IDENTIFIER \ Reserved
  | IDENTIFIER "!"
  | IDENTIFIER "?"
  ;


lexical OPERATIONNoReserved 
  = IDENTIFIER
  | IDENTIFIER "!"
  | IDENTIFIER "?"
  ;

lexical VARIABLE    
  = "$" IDENTIFIER
  | "@" IDENTIFIER
  | "@@" IDENTIFIER
  | id: IDENTIFIER \ Reserved
  ;

syntax STRING
  = BSTR TAIL
  | ISTR
  | SSTR 
  ;
  
lexical SSTR = [\'] QStrChar* [\'];
lexical ISTR = [\"] STRCHAR* [\"];
lexical BSTR = [\"] STRCHAR* "#{";
lexical MSTR = "}"  STRCHAR* "#{";
lexical ESTR = "}" STRCHAR* [\"];
  
lexical STRCHAR
  = ![\\\"#]
  | [#] !>> [{]
  | [\\][\\\"nrtf]
  ;
  
syntax TAIL
  = EXPR MSTR TAIL
  | EXPR ESTR
  ;
  
lexical DQStrChar
  = ![\"\\]
  | [\\][\"\\]
  ;

lexical QStrChar
  = ![\'\\]
  | [\\][\'\\]
  ;
  
  
lexical REGEXP    
= "/" RegexpChar* "/" [iop]
;

lexical RegexpChar
  = ![\\/]
  | [\\][/\\]
  ;

lexical IDENTIFIER = ([a-zA-Z_] !<< [a-zA-Z_][a-zA-Z0-9_]* !>> [a-zA-Z0-9_]) ;

keyword Reserved 
  = "yield" | "super" | "and" | "or" | "not" | "if" | "then" | "unless" | "else" 
  | "elsif" | "while" | "end" | "do" | "for" | "begin" | "class" | "case"
  | "module" | "def" | "when" | "rescue" | "ensure" | "until" | "nil" | "self"
  | "true" | "false"
  ;  


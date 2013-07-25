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
  = STMTS
  ;

syntax STMTS
 = NL* {STMT TERM}+ NL* // possibly this could be simplified.
 | NL*
 ;
 
syntax TERM  = ";" | NL+ ; // need to have plus, otherwise no comments inbetween...

lexical NL
  = [\n] (Comment|[\ \t\n])* !>> [\ \t\n#]
  ;
  
syntax STMT
  = "if" EXPR THEN STMTS ELSIF* ELSE? "end"
  | "unless" EXPR THEN STMTS ELSE? "end"
  | "while" EXPR DO STMTS "end"
  | "until" EXPR DO STMTS "end"
  | "case" STMTS WHEN+ ELSE? "end"
  | "for" BLOCK_VAR "in" EXPR DO STMTS "end"
  | "begin" STMTS RESCUE+ ELSE? ENSURE? "end"
  | "class" IDENTIFIER EXTEND? STMTS "end" 
  | "module" IDENTIFIER STMTS "end"
  | "def" FNAME "(" ARGLIST ")" STMTS "end"
  | "def" FNAME TERM STMTS "end"
  | "def" SINGLETON ("."|"::") FNAME "(" ARGLIST ")" STMTS "end"
  | "def" SINGLETON ("."|"::") FNAME TERM STMTS "end"
  
  // NB: CALLARGS are not optional here.
  // But still it leads to all kinds of ambiguities
  // maybe only allow primaries in commands and no blocks
  | YIELD1 !>> "("  CALLARGS 
  | OPERATION1 !>> "("  CALLARGS 
//  | OPERATION2 !>> "("  CALLARGS  BLOCK
  | SUPER1  !>> "(" CALLARGS 
  | PRIMARY "." OPERATION2 !>> "(" CALLARGS 
  | PRIMARY "::" OPERATION3 !>> "(" CALLARGS 
//  | PRIMARY "." OPERATION4 !>> "(" CALLARGS  BLOCK
//  | PRIMARY "::" OPERATION5 !>> "("  CALLARGS BLOCK
  
  | LHS "=" STMT ! expr
  | LHS OP_ASGN STMT ! expr
  
  | expr: EXPR
  ;
  
// Workaround
syntax OPERATION1 = OPERATION;
syntax OPERATION2 = OPERATION;
syntax OPERATION3 = OPERATION;
syntax OPERATION4 = OPERATION;
syntax OPERATION5 = OPERATION;
syntax OPERATION6 = OPERATION;
syntax YIELD1 = "yield";
syntax SUPER1 = "super";

syntax THEN = TERM | "then" | TERM "then" ;
syntax DO   = TERM | "do" | TERM "do" ;
syntax ELSIF = "elsif" EXPR THEN STMTS;
syntax ELSE = "else" STMTS;
syntax WHEN = "when" WHEN_ARGS THEN STMTS;
syntax RESCUE = "rescue" {EXPR ","}* DO STMTS;
syntax ENSURE = "ensure" STMTS;
syntax EXTEND = "\<" IDENTIFIER; // should probably be expression

syntax BLOCK
  = "{" STMTS "}"
  | "{" "|" BLOCK_VAR "|" STMTS "}"
  | "do" STMTS "end"
  | "do" "|" BLOCK_VAR "|" STMTS "end"  
  ;

syntax PRIMARY
  = "(" STMTS ")"
  | LITERAL
  | VARIABLE ! id 
  | "nil"
  | "self"
  | "true"
  | "false"
  | [a-zA-Z_0-9] !<< "::" IDENTIFIER
  | [a-zA-Z_0-9] !<< "[" {EXPR ","}* "]"
  | "yield" 
  | YIELD2 >> "(" "(" CALLARGS? ")"
  | OPERATION
  | OPERATION BLOCK
  | POPERATION1 >> "(" "(" CALLARGS? ")"
  | POPERATION2 >> "(" "(" CALLARGS? ")" BLOCK
  | "super"
  | SUPER2 >> "(" "(" CALLARGS? ")"
  | PRIMARY >> "[" "[" {EXPR ","}* "]"
  | PRIMARY "." OPERATION 
  | PRIMARY "::" OPERATION
  | PRIMARY "." OPERATION BLOCK
  | PRIMARY "::" OPERATION BLOCK
  | PRIMARY "." POPERATION3 >> "(" "(" CALLARGS? ")"
  | PRIMARY "::" POPERATION4 >> "(" "(" CALLARGS? ")"
  | PRIMARY "." POPERATION5 >> "(" "(" CALLARGS? ")" BLOCK
  | PRIMARY "::" POPERATION6 >> "(" "(" CALLARGS? ")" BLOCK
  ;

// Workaround
syntax POPERATION1 = OPERATION;
syntax POPERATION2 = OPERATION;
syntax POPERATION3 = OPERATION;
syntax POPERATION4 = OPERATION;
syntax POPERATION5 = OPERATION;
syntax POPERATION6 = OPERATION;
syntax YIELD2 = "yield";
syntax SUPER2 = "super";


syntax EXPR 
  = PRIMARY
  > [a-zA-Z0-9_] !<< "!" EXPR
  | "~" EXPR
  | "+" !>> [\ \t] EXPR
  > right EXPR "**" EXPR
  > "-" !>> [\ \t] EXPR
  > left ( EXPR "*" EXPR
    | EXPR "/" EXPR
    | EXPR "%" EXPR
  )
  > left ( EXPR "+" EXPR
    | EXPR "-" EXPR
  )
  > right ( EXPR "\<\<" EXPR // right?
    | EXPR "\>\>" EXPR
  )
  > left EXPR "&" EXPR // left?
  > left ( EXPR "|" EXPR // left?
    | EXPR "^" EXPR
  )
  > non-assoc ( EXPR "\>" EXPR // left? they are methods...
    | EXPR "\>=" EXPR
    | EXPR "\<" EXPR
    | EXPR "\<=" EXPR
  )
  > non-assoc ( EXPR "\<=\>" EXPR // left?
    | EXPR "==" EXPR
    | EXPR "===" EXPR
    | EXPR "!=" EXPR
    | EXPR "=~" EXPR
    | EXPR "!~" EXPR
  )
  > left EXPR "&&" EXPR
  > left EXPR "||" EXPR
  > non-assoc ( EXPR ".." EXPR
    | EXPR "..." EXPR
  )
  > EXPR [a-zA-Z0-9_] !<< "?" EXPR ":" EXPR
  > LHS "=" EXPR
  | LHS OP_ASGN EXPR
  > "not" EXPR
  > left (EXPR "and" EXPR 
    | EXPR "or" EXPR
  )
  > left ( EXPR "if" EXPR
    | EXPR "while" EXPR
    | EXPR "unless" EXPR
    | EXPR "until" EXPR
  )
//  | bracket "(" EXPR ")"
;
    
 
syntax OP_ASGN 
  = "+=" | "-=" | "*=" | "/=" | "%=" | "**=" | "&=" | "|=" 
  | "^=" | "\<\<=" | "\>\>=" | "&&=" | "||="
  ;
 
syntax WHEN_ARGS   
  = {EXPR ","}+ 
  | {EXPR ","}+ "," STAR EXPR
  | STAR EXPR
  | /* empty */
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

// TODO: default params.
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
  = IDENTIFIER "=" EXPR
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
  = [:] !<< ":" FNAME
  | [:] !<< ":" VARIABLE ! id // use :FNAME instead of :VARIABLE
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


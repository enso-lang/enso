module rsc::core::grammar::models::Lexical

syntax Atom
  = Int
  | Sym
  | Str
  | Real
  ;
  
lexical Int
  = [\-+]?[0-9]+ !>> [0-9]
  ;
  
lexical Str
  = [\"] StrChar* [\"]
  ;
  
lexical StrChar
  = ![\"]
  | [\\][\\\"]
  ;
  
lexical Sym
  = ([a-zA-Z0-9_] !<< [\\a-zA-Z_][a-zA-Z0-9_]* !>> [a-zA-Z0-9_]) \ Reserved
  ; 
  
lexical Real
  = [0-9]+ "." [0-9]+ !>> [0-9]
  ;
  
keyword Reserved = ;

/* all the white space chars defined in Unicode 6.0 */ 
lexical Whitespace 
  = [\u0009-\u000D \u0020 \u0085 \u00A0 \u1680 \u180E \u2000-\u200A \u2028 \u2029 \u202F \u205F \u3000]
  ; 

lexical Comment = @category="Comment" "//" ![\n\r]* $;

layout Standard 
  = WhitespaceOrComment* !>> [\u0009-\u000D \u0020 \u0085 \u00A0 \u1680 \u180E \u2000-\u200A \u2028 \u2029 \u202F \u205F \u3000] !>> "//";
  
syntax WhitespaceOrComment 
  = whitespace: Whitespace
  | comment: Comment
  ; 
  
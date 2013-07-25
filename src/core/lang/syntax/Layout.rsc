module core::lang::\syntax::Layout

//extend lang::std::Whitespace;

lexical Comment 
  = @category="Comment" "#" ![\n\r]* $
//  | @category="Comment" ^"=begin" DocChar* ^"=end"
  ;
  
//lexical DocChar
//  = ![=]
//  | [=] !>> "=end"
//  ;

lexical Whitespace 
  = [\t\ ]
  ;

layout Standard 
  = WhitespaceOrComment* !>> [\t\ ] !>> "#";
  
lexical WhitespaceOrComment 
  = whitespace: Whitespace
  | comment: Comment
  ; 

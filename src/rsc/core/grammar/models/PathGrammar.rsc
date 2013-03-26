module rsc::core::grammar::models::PathGrammar

extend rsc::core::grammar::models::Lexical;

start syntax Path 
  = anchro: "." type
  | anchor: ".." type
  | sub: Path? parent "/" Sym name Subscript? subscript
  ;
  
syntax Subscript
  = "[" Key key "]"
  ;
  
syntax Key
  = const: Atom value
  | path: Path path
  ;  


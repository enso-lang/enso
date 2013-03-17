module rsc::core::grammar::models::PathSchema

data Key
  = const(Const const)
  | path(Path path)
  ;

data Const
  = const(value \value)
  ;

data Path
  = key(Key key)
  | anchor(Anchor anchor)
  | sub(Sub sub)
  ;
  
data Anchor
  = anchor(str \type)
  ;

data Sub
  = sub(list[Path] parent, str name, list[Key] key)
  ;


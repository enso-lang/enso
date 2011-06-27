


=begin

add new rules for each nonterminal S:
 _S ::= 


t_sym(X) = add rule _X with alts according to
  x:Y -> x:t_sym(Y)
  p -> _p (primitive)
  X*+ -> _X_Elt* (add iter_rule(X))
  X? -> _X_Opt? (add opt_rule(X))
  X -> _X_Call (add call_rule(X))
  "x" -> "x"
  [Y] ss -> [_Y] t_sym(ss)

new_rule(X)
  _X ::=
        templatized body of X (add all alts) (should we cons here?)
      | [_X_Cond] "$if" "(" cond:EXP ")" "{" body:_X "}" "else" "{" else:_X "}"
      | [_X_Call] "$" name:sym ":X" "(" args:{EXP ","}* ")"


iter_rule(X) =
  _X_Iter ::= #NB: use sep if X was in a sep
  	  | _X
  	  | [_X_Iter] "$for" "(" var:sym ":" exp:EXP ")" "{" body:_X_Iter+ "}"
          | [_X_Cond] "$if" "(" cond:EXP ")" "{" body:_X_Iter+ "}"

opt_rule(X) =
  _X_Opt ::=
          | _X
          | [_X_Cond] "$if" "(" cond:EXP ")" "{" body:_X_Opt "}"

func(X) ::= // add alts to generic DEF
  DEF ::= "def" "X" name:sym "(" formals:{VAR ","}* ")" "{" body:_X "}"
       |  "def" "X?" name:sym "(" formals:{VAR ","}* ")" "{" body:_X_Opt "}"
       |  "def" "X*" name:sym "(" formals:{VAR ","}* ")" "{" body:_X_Iter+ "}"


NB: don't deal with + lists, cannot know non-optionality from for loops.
=end

  _Grammar ::= [_Grammar] "start" \start:_sym rules:_Rule_Elt*


  _Rule_Elt ::= Rule
  	     | _Rule
  	     | [_Rule_Iter] "for" "(" var:sym ":" exp:EXP ")" body:_Rule_Elt
 	     | [_Rule_Group] "{" elements:_Rule_Elt* "}"

  _Rule ::= [_Rule] name:_sym "::=" arg:_Alt

  _Alt ::= [_Alt] alts:{_Create "|"}+

  _Create_Elt ::= Create
               |  _Create
               | [_Create_Iter]"for" "(" var:sym ":" exp:EXP ")" body:_Create_Elt
    	       | [_Create_Group] "{" elements:_Create_Elt* "}"

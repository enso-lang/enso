module core::lang::\syntax::Compile

import core::lang::\syntax::EnsoLanguage;
import core::lang::\syntax::JavascriptAST;

//"if" EXPR THEN STMTS ELSIF* ELSE? "end"


Statement stmt2js((STMT)`if <EXPR e> <THEN _> <STMTS body> <ELSIF* eifs> else <STMTS ebody> end`)
  = 4;

Statement stmt2js((STMT)`if <EXPR e> <THEN _> <STMTS body> <ELSIF* eifs> end`)
  = 4;
  
Expression var2js((VARIABLE)`$<IDENTIFIER id>`) = 
  { throw "$ vars not supported"; };

Expression var2js((VARIABLE)`@<IDENTIFIER id>`) 
  = member(member(variable("self"), "$", "<id>"));
  
Expression var2js((VARIABLE)`@@<IDENTIFIER id>`) 
  = member(member(member(variable("self"), "_class_"), "$"), "<id>");
  
  
Expression expr2js((EXPR)`<PRIMARY p>`) = prim2js(p);
Expression expr2js((EXPR)`!<EXPR e>`) = unary(not(), true, expr2js(e));
Expression expr2js((EXPR)`~<EXPR e>`) = unary(bitNot(), true, expr2js(e));
Expression expr2js((EXPR)`+<EXPR e>`) = unary(UnaryOperator::plus(), true, expr2js(e));
Expression expr2js((EXPR)`-<EXPR e>`) = unary(UnaryOperator::min(), true, expr2js(e));
Expression expr2js((EXPR)`not <EXPR e>`) = unary(UnaryOperator::not(), true, expr2js(e));

Expression expr2js((EXPR)`<EXPR l> ** <EXPR r>`) 
  = call(member(variable("Math"), "pow"), [exp2js(l), expr2js(r)]);

Expression expr2js((EXPR)`<EXPR l> * <EXPR r>`) = binary(times(), expr2js(l), expr2js(r));
Expression expr2js((EXPR)`<EXPR l> / <EXPR r>`) = binary(div(), expr2js(l), expr2js(r));
Expression expr2js((EXPR)`<EXPR l> % <EXPR r>`) = binary(rem(), expr2js(l), expr2js(r));
Expression expr2js((EXPR)`<EXPR l> + <EXPR r>`) = binary(BinaryOperator::plus(), expr2js(l), expr2js(r));
Expression expr2js((EXPR)`<EXPR l> - <EXPR r>`) = binary(BinaryOperator::min(), expr2js(l), expr2js(r));
Expression expr2js((EXPR)`<EXPR l> & <EXPR r>`) = binary(bitAnd(), expr2js(l), expr2js(r));
Expression expr2js((EXPR)`<EXPR l> | <EXPR r>`) = binary(bitOr(), expr2js(l), expr2js(r));
Expression expr2js((EXPR)`<EXPR l> ^ <EXPR r>`) = binary(bitXor(), expr2js(l), expr2js(r));

// TODO!!!
Expression expr2js((EXPR)`<EXPR l> == <EXPR r>`) = binary(equals(), expr2js(l), expr2js(r));
Expression expr2js((EXPR)`<EXPR l> === <EXPR r>`) = { throw "Unsupported: ==="; };
Expression expr2js((EXPR)`<EXPR l> != <EXPR r>`) = binary(notEquals(), expr2js(l), expr2js(r));

Expression expr2js((EXPR)`<EXPR l> =~ <EXPR r>`) = call(member(expr2js(l), "match"), [expr2js(r)]);
Expression expr2js((EXPR)`<EXPR l> !~ <EXPR r>`) = unary(not(), true, call(member(expr2js(l), "match"), [expr2js(r)]));
Expression expr2js((EXPR)`<EXPR l> && <EXPR r>`) = binary(and(), expr2js(l), expr2js(r));
Expression expr2js((EXPR)`<EXPR l> || <EXPR r>`) = binary(or(), expr2js(l), expr2js(r));
Expression expr2js((EXPR)`<EXPR l> .. <EXPR r>`) = { throw "Unsupported: .."; };
Expression expr2js((EXPR)`<EXPR l> ... <EXPR r>`) = { throw "Unsupported: ..."; };

Expression expr2js((EXPR)`<EXPR l> and <EXPR r>`) = binary(and(), expr2js(l), expr2js(r));
Expression expr2js((EXPR)`<EXPR l> or <EXPR r>`) = binary(or(), expr2js(l), expr2js(r));

Expression expr2js((EXPR)`<EXPR l> if <EXPR r>`) 
  = conditional(expr2js(r), exp2js(l), literal(null()));
   
Expression expr2js((EXPR)`<EXPR l> while <EXPR r>`) 
  = call(function("", [], [], "", \while(exp2js(r), expression(expr2js(l)))), []);
   
Expression expr2js((EXPR)`<EXPR l> unless <EXPR r>`) 
  = conditional(expr2js(r), literal(null()), exp2js(l));

Expression expr2js((EXPR)`<EXPR l> until <EXPR r>`) 
  = call(function("", [], [], "", doWhile(unary(not(), true, exp2js(r)), expression(expr2js(l)))), []);

Expression expr2js((EXPR)`<EXPR c> ? <EXPR t> : <EXPR e>`) 
  =  conditional(expr2js(c), exp2js(t), exp2js(e));

Expression expr2js((EXPR)`<LHS l> = <EXPR r>`) = 3;
Expression expr2js((EXPR)`<LHS l> <OP_ASGN op> <EXPR r>`) = 3;


Expression prim2js((PRIMARY)`nil`) = literal(null());
Expression prim2js((PRIMARY)`self`) = variable("self");
Expression prim2js((PRIMARY)`true`) = literal(boolean(true));
Expression prim2js((PRIMARY)`false`) = literal(boolean(false));

Expression prim2js((PRIMARY)`(<STMTS stmts>)`) = 
   call(function("", [], [], "", block([ stmt2js(s) | s <- stmts ])), []);

Expression prim2js((PRIMARY)`<LITERAL lit>`) = 3;
Expression prim2js((PRIMARY)`<VARIABLE var>`) = var2js(var);
Expression prim2js((PRIMARY)`::<IDENTIFIER id>`) = "<id>";

Expression prim2js((PRIMARY)`[<{EXPR ","}* elts>]`) = 
   array([ expr2js(e) | e <- elts ]);
   
Expression prim2js((PRIMARY)`yield`) = 3;
Expression prim2js((PRIMARY)`yield(<CALLARGS args>)`) = 3;
Expression prim2js((PRIMARY)`yield()`) = 3;
Expression prim2js((PRIMARY)`<OPERATION op>`) = 3;
Expression prim2js((PRIMARY)`<OPERATION op> <BLOCK block>`) = 3;
Expression prim2js((PRIMARY)`<POPERATION1 op>(<CALLARGS args>)`) = 3;
Expression prim2js((PRIMARY)`<POPERATION1 op>()`) = 3;
Expression prim2js((PRIMARY)`<POPERATION2 op>(<CALLARGS args>) <BLOCK block>`) = 3;
Expression prim2js((PRIMARY)`<POPERATION2 op>() <BLOCK block>`) = 3;
Expression prim2js((PRIMARY)`super`) = 3;
Expression prim2js((PRIMARY)`super(<CALLARGS args>)`) = 3;
Expression prim2js((PRIMARY)`super()`) = 3;
Expression prim2js((PRIMARY)`<HASH h>`) = 3;
Expression prim2js((PRIMARY)`<PRIMARY p>[<{EXPR ","}* es>]`) = 3;
Expression prim2js((PRIMARY)`<PRIMARY p>.<OPERATIONNoReserved op>`) = 3;
Expression prim2js((PRIMARY)`<PRIMARY p>::<OPERATIONNoReserved op>`) = 3;
Expression prim2js((PRIMARY)`<PRIMARY p>.<OPERATIONNoReserved op> <BLOCK b>`) = 3;
Expression prim2js((PRIMARY)`<PRIMARY p>::<OPERATIONNoReserved op> <BLOCK b>`) = 3;

Expression prim2js((PRIMARY)`<PRIMARY p>.<POPERATION3 op>(<CALLARGS args>)`) = 3;
Expression prim2js((PRIMARY)`<PRIMARY p>::<POPERATION4 op>(<CALLARGS args>)`) = 3;
Expression prim2js((PRIMARY)`<PRIMARY p>.<POPERATION3 op>()`) = 3;
Expression prim2js((PRIMARY)`<PRIMARY p>::<POPERATION4 op>()`) = 3;

Expression prim2js((PRIMARY)`<PRIMARY p>.<POPERATION5 op>(<CALLARGS args>) <BLOCK b>`) = 3;
Expression prim2js((PRIMARY)`<PRIMARY p>::<POPERATION6 op>(<CALLARGS args>) <BLOCK b>`) = 3;
Expression prim2js((PRIMARY)`<PRIMARY p>.<POPERATION5 op>() <BLOCK b>`) = 3;
Expression prim2js((PRIMARY)`<PRIMARY p>::<POPERATION6 op>() <BLOCK b>`) = 3;


// http://stackoverflow.com/questions/894860/set-a-default-parameter-value-for-a-javascript-function
//  a = typeof a !== 'undefined' ? a : 42;
//   b = typeof b !== 'undefined' ? b : 'default_b';
   

list[Statement] defaultInits((DEFAULTS)`<{DEFAULT ","}+ ds>`)
  = [ assign(variable("<d.id>"), 
        conditional(binary(longNotEquals(), unary(typeof(), true, "<d.id>"),
          literal(string("undefined"))), variable("<d.id>"), 
            expr2js(d.expr))) | d <- ds ];

list[Param] defaultParams((DEFAULTS)`<{DEFAULT ","}+ ds>`)
  = [ variable("<d.id>") | d <- ds ];

list[Param] params({IDENTIFIER ","}+ ids) = [ variable("<i>") | i <- ids ];

// Rest params: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/rest_parameters
//  var args = Array.prototype.slice.call(arguments, f.length);

list[Statement] restInits(str f, IDENTIFIER rest)
  = [ varDecl( [ variableDeclarator(variable("<rest>", expression(e))) ], "var") ]
  when 
    e :=  call(member(member(member(variable("Array"), "prototype"), "slice"), "call"), 
             [variable("arguments"), member(f, "length")]);
  


Function arglist2func(str f, (ARGLIST)`<{IDENTIFIER ","}+ ids>, <DEFAULTS defs>, <STAR _> <IDENTIFIER rest>, <AMP _> <IDENTIFIER b>`) 
  = { throw "Unsupported: block param after rest args."; };
  
Function arglist2func(str f, (ARGLIST)`<{IDENTIFIER ","}+ ids>, <DEFAULTS defs>, <STAR _> <IDENTIFIER rest>`) 
  = function(f, [params(ids) + defaultParams(defs)], [], "", 
      block(defaultInits(defs) + restInits(f, rest)));

Function arglist2func(str f, (ARGLIST)`<{IDENTIFIER ","}+ ids>, <DEFAULTS defs>, <AMP _> <IDENTIFIER b>`)
  = { throw "Unsupported: block param after default args."; };

Function arglist2func(str f, (ARGLIST)`<{IDENTIFIER ","}+ ids>, <DEFAULTS defs>`) 
  = function(f, [params(ids) + defaultParams(defs)], [], "", 
      block(defaultInits(defs)));

Function arglist2func(str f, (ARGLIST)`<{IDENTIFIER ","}+ ids>, <STAR _> <IDENTIFIER rest>, <AMP _> <IDENTIFIER b>`) 
  = { throw "Unsupported: block param after rest args."; };

Function arglist2func(str f, (ARGLIST)`<{IDENTIFIER ","}+ ids>, <STAR _> <IDENTIFIER rest>`)
  = function(f, [params(ids)], [], "", 
      block(restInits(f, rest)));

Function arglist2func(str f, (ARGLIST)`<{IDENTIFIER ","}+ ids>, <AMP _> <IDENTIFIER b>`)
  = function(f, [params(ids) + params(b)], [], "", 
      block([]));

Function arglist2func(str f, (ARGLIST)`<{IDENTIFIER ","}+ ids>`)
  = function(f, [params(ids)], [], "", 
      block([]));

Function arglist2func(str f, (ARGLIST)`<DEFAULTS defs>, <STAR _> <IDENTIFIER rest>, <AMP _> <IDENTIFIER b>`)
  = { throw "Unsupported: block param after rest args."; };

Function arglist2func(str f, (ARGLIST)`<DEFAULTS defs>, <STAR _> <IDENTIFIER rest>`)
  = function(f, [defaultParams(defs)], [], "", 
      block(defaultInits(defs) + restInits(f, rest)));

Function arglist2func(str f, (ARGLIST)`<DEFAULTS defs>, <AMP _> <IDENTIFIER b>`)
  = { throw "Unsupported: block param after default args."; };
  
Function arglist2func(str f, (ARGLIST)`<DEFAULTS defs>`) 
  = function(f, [defaultParams(defs)], [], "", 
      block(defaultInits(defs)));

Function arglist2func(str f, (ARGLIST)`<STAR _> <IDENTIFIER rest>, <AMP _> <IDENTIFIER b>`) 
  = { throw "Unsupported: block param after rest args."; };

Function arglist2func(str f, (ARGLIST)`<STAR _> <IDENTIFIER rest>`) 
  = function(f, [], [], "", 
      block(restInits(f, rest)));

Function arglist2func(str f, (ARGLIST)`<AMP _> <IDENTIFIER b>`)
  = function(f, [params(b)], [], "", 
      block([]));

Function arglist2func(str f, (ARGLIST)``)
  = function(f, [], [], "", 
      block([]));




// < and > stuff at the end...
Expression expr2js((EXPR)`<EXPR l> \<=\> <EXPR r>`) =
  conditional(binary(lt(), l1, r1), literal(number(-1)),
    conditional(binary(gt(), l1, r1), literal(number(1)), literal(number(0))))
  when l1 := expr2js(l), r1 := expr2js(r); 


Expression expr2js((EXPR)`<EXPR l> \>= <EXPR r>`) = binary(geq(), expr2js(l), expr2js(r));
Expression expr2js((EXPR)`<EXPR l> \<= <EXPR r>`) = binary(leq(), expr2js(l), expr2js(r));
Expression expr2js((EXPR)`<EXPR l> \> <EXPR r>`) = binary(gt(), expr2js(l), expr2js(r));
Expression expr2js((EXPR)`<EXPR l> \< <EXPR r>`) = binary(lt(), expr2js(l), expr2js(r));
Expression expr2js((EXPR)`<EXPR l> \<\< <EXPR r>`) = binary(shiftLeft(), expr2js(l), expr2js(r));
Expression expr2js((EXPR)`<EXPR l> \>\> <EXPR r>`) = binary(shiftRight(), expr2js(l), expr2js(r));
  

  
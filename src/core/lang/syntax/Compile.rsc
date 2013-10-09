module core::lang::\syntax::Compile

import core::lang::\syntax::EnsoLanguage;
import core::lang::\syntax::JavascriptAST;
import IO;
import String;


list[str] ASSIGNED = [];

void resetAssignedVars() { ASSIGNED = []; }
void assignVar(str name) { ASSIGNED += [name]; }
void assignedVars() = ASSIGNED;




list[Statement] mainBody() = [
  variableDeclaration([variableDeclarator(variable("requirejs"), 
    expression(call(variable("require"), 
          [literal(string("requirejs"))])))], "var"),
 // requirejs.config({ nodeRequire: require, baseUrl: 'js' });
    call(member(variable("requirejs"), "config"), [
           object([<id("nodeRequire"), variable("require"), "">,
                   <id("baseURL"), literal(string("js")), "">])]), 
    x];
    

list[str] requiredPaths(STMTS body)
  = [ "<p>"[1..-1] | /(STMT)`require <STRING p>` := body ];

list[str] paths2modules(list[str] paths)
  = [ capitalize(split("/", p)[-1]) | p <- paths ];


Statement declareModule(list[str] reqPaths)
  = expression(call(variable("define"), [
       array([ literal(string(p)) | p <- reqPaths]),
       function("", [variable(n) | n <- paths2modules(reqPaths)], [], "",
         block([
           variableDeclaration(variableDeclarator(variable(name)), "var"),
           stmt2js(body),
           assignment(assign(), variable(name), exportedObject(body)),
           \return(variable(name))
         ]))
     ]));
  
  


Program unit2js((Unit)`<STMTS stmts>`)
  = program(stmts2js(stmts).stats);

// Statement lists

Statement stmts2js((STMTS)`<NL* _><{STMT TERM}+ stmts><NL* _>`)
  = block([ stmt2js(s) | s <- stmts, bprintln("S = <s>") ]);
  
default Statement stmts2js(STMTS _) = empty();

default Statement stmt2js(STMT x) {
  println("WARNING: unhandled stmt: <x>");
  return empty();
}


// Statements
Statement stmt2js((STMT)`if <EXPR e> <THEN _> <STMTS body> <ELSIF* eifs> else <STMTS ebody> end`)
  = \if(expr2js(e), stmts2js(body), elsifs2js(eifs, stmts2js(ebody)));

Statement stmt2js((STMT)`if <EXPR e> <THEN _> <STMTS body> <ELSIF* eifs> end`)
  = \if(expr2js(e), stmts2js(body), elsifs2js(eifs, empty()));

Statement elsifs2js(ELSIF* eifs, Statement els) 
  = ( els | \if(expr2js(e), stmts2js(b), it) 
      | (ELSIF)`elsif <EXPR e> <THEN _> <STMTS b>` 
        <- reverse([ eif | eif <- eifs]));
  
Statement stmt2js((STMT)`unless <EXPR e> <THEN _> <STMTS body> else <STMTS ebody> end`)
  = \if(unary(not(), true, expr2js(e)), stmts2js(body), stmts2js(ebody));

Statement stmt2js((STMT)`while <EXPR e> <DO _> <STMTS body> end`)
  = \while(expr2js(e), stmts2js(body));

Statement stmt2js((STMT)`until <EXPR e> <DO _> <STMTS body> end`)
  = \while(unary(not(), true, expr2js(e)), stmts2js(body));
  
  
str caseVar(STMT cas) = "case$<cas@\loc.offset>";

Statement stmt2js(t:(STMT)`case <STMTS stmts> <WHEN+ whens> else <STMTS ebody> end`)
  = call(function("", [variable(x)], [], "", whens2js(x, whens, stmts2js(ebody))), [stmts2exp(stmts)])
  when x := caseVar(t);

  
Statement stmt2js((STMT)`case <STMTS stmts> <WHEN+ whens> end`)
  = call(function("", [variable(x)], [], "", whens2js(x, whens, empty())), [stmts2exp(stmts)])
  when x := caseVar(t);
  
Statement when2js(WHEN+ whens, Statement els, str x) 
  = ( els | \if(whenArgs2Cond(wa, x), stmts2js(stmts), it) 
      | (WHEN)`when <WHEN_ARGS wa> <THEN _> <STMTS stmts>` <- reverse([ w <- whens ]) ); 


Expression whenArgs2Cond((WHEN_ARGS)`<{EXPR ","}+ es>`, str x)
  = ( literal(boolean(false))  
       | binary(or(), binary(longEquals(), x, expr2js(e)), it)
       | EXPR e <- reverse([ e | e <- es ]) );

Expression whenArgs2Cond((WHEN_ARGS)`<{EXPR ","}+ es>, <STAR _> <EXPR rest>`, str x)
  = ( binary(\in(), variable(x), expr2js(rest)) 
       | binary(or(), binary(longEquals(), x, expr2js(e)), it)
       | EXPR e <- reverse([ e | e <- es ]) );

Expression whenArgs2Cond((WHEN_ARGS)`<STAR _> <EXPR rest>`, str x)
  = binary(\in(), variable(x), expr2js(rest)); 

Expression whenArgs2Cond((WHEN_ARGS)``, str x)
  = literal(boolean(false)); 

Statement stmt2js((STMT)`for <BLOCK_VAR bv> in <EXPR e> <DO _> <STMTS stmts> end`)
  = { throw "For-in not supported."; };
 
str tryVar(STMT s) = "caught$<s@\loc.offset>";
  
Statement stmt2js(t:(STMT)`begin <STMTS stmts> <RESCUE+ rescues> else <STMTS els> ensure <STMTS ens> end`)
  = \try(stmts2js(stmts), catchClause(variable(x), rescues2ifs(rescues, stmts2js(els), x)), stmts2js(ens))
  when x := tryVar(t);

Statement stmt2js(t:(STMT)`begin <STMTS stmts> <RESCUE+ rescues> else <STMTS els> end`)
  = \try(stmts2js(stmts), catchClause(variable(x), rescues2ifs(rescues, stmts2js(els), x)))
  when x := tryVar(t);
  
Statement stmt2js(t:(STMT)`begin <STMTS stmts> <RESCUE+ rescues> ensure <STMTS ens> end`)
  = \try(stmts2js(stmts), catchClause(variable(x), rescues2ifs(rescues, empty(), x)), stmts2js(ens))
  when x := tryVar(t);
  
Statement stmt2js((STMT)`begin <STMTS stmts> <RESCUE+ rescues> end`)
  = \try(stmts2js(stmts), catchClause(variable(x), rescues2ifs(rescues, empty(), x)))
  when x := tryVar(t);


Statement rescues2ifs(RESCUE+ rescues, Statement els, str x)
  = ( els | rescue2clause(r, it, x) | r <- reverse([ r | r <- rescues ]) );

Statement rescue2clause((RESCUE)`rescue <{EXPR ","}* es> <DO _> <STMTS body>`, str x)
  = TODO;

// TODO uncomment
//Statement rescue2clause((RESCUE)`rescue <EXPR e> =\> <IDENTIFIER y> <DO _> <STMTS body>`, Statement els, str x)
//  = \if(binary(instanceOf(), variable(x), expr2js(e)),
//     call(function("", [variable("<y>")], [], "", stmts2js(body)), [variable(x)]), els);




// Definitions


// Modules

/*
Module ::= [Module] "define(". Imports "{">/
                    "var" name:sym ";"/
                    defs:Def* @/2 /2
                    name:sym "=" "{"/> defs:Export* /2 /<"};"/
                    "return" name:sym .";"/
                    <"})"/
Imports ::= "["/> requires:([Require] path:str)* @(.","/) </"]," /
            "function(". requires:([Require] name:sym)* @(.",") .")"

*/


  
//Mixin   ::= [Mixin] "var" name:sym "= MakeMixin(". 
// Includes ."," "function() {" Body "});"


list[Expression] includedModules(STMTS body) 
  = [ expr2js(e) | (STMT)`include <EXPR e>` <- body.stmts ];
  
Statement declareMixin(str name, STMTS body)
  = varDecl([variableDeclarator(variable(name), 
               expression(call(variable("MakeMixin"), 
                  [array(includedModules(body)), 
                  function("", [], [], "", stmts2js(body))
                  ])))], "var");
  

Statement stmt2js((STMT)`module <IDENTIFIER name> <STMTS body> end`)
  = declareMixin("<name>", body);

Statement declareClass(str name, Expression super, STMTS body)
  = varDecl([variableDeclarator(variable(name), 
               expression(call(variable("MakeClass"), 
                  [literal(string("\"<id>\"")), 
                  super,
                  array(includedModules(body)),
                  function("", [], [], "", meta2js(body)),
                  function("", [variable("super$")], [], "", stmts2js(body))
                  ])))], "var");

Statement stmt2js((STMT)`class <IDENTIFIER id> <STMTS body> end`)
  = declareClass("<id>", literal(null()), body);
  

str renameMethodSym("[]") = "_get";
str renameMethodSym("[]=") = "_set";
default str renameMethodSym(str name) = name;

Statement declareMethod(IDENTIFIER f, ARGLIST args, STMTS body) {
  resetAssignedVars();
  func = arglist2func(args);
  sym = renameMethodSym("<f>");
  func.name = sym;
  // we know it's a block
  func.statBody.stats = 
    [varDecl([variableDeclarator(
                variable("self"), expression(this()))
                ], "var"), *func.statBody.stats];
  func.statBody.stats += 
    [ variableDeclaration([variableDeclarator(variable(a), none())])
                        | a <- assignedVars()] 
    + stmts2js(body).stats;
  return assignment(assign(), member(this(), sym), 
              func);
}

Statement stmt2js((STMT)`def <IDENTIFIER f>(<ARGLIST args>) <STMTS body> end`)
  = declareMethod(f, args, body); 

Statement stmt2js((STMT)`def <IDENTIFIER f> <TERM _> <STMTS body> end`) 
  = declareMethod(f, (ARGLIST)``, body);

// Attrs
/*
Reader  ::= "this.". name:sym "=" "function()" "{" "return" "this"."."."$".".". name:sym "}" .";"
Writer  ::= "this.". "set_".name:sym "=" "function(val)" "{" "this"."."."$".".". name:sym " = val" "}" .";"
*/

Statement reader(str name)
  = assignment(assign(), member(this(), name), 
      function("", [], [], "", \return(member(member(this(), "$"), name))));

Statement writer(str name)
  = assignment(assign(), member(this(), "set_" + name), 
      function("", [variable("val")], [], "", 
          assignment(assign(), member(member(this(), "$"), name), variable(val))));

Statement stmt2js((STMT)`attr_reader :<IDENTIFIER id>`)
  = reader("<id>");

// TODO: let stmt2js return lists of statements.
Statement stmt2js((STMT)`attr_accessor :<IDENTIFIER id>`)
  = block([reader("<id>"), writer("<id>")]);
  
// Variables
 
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

Expression prim2js((PRIMARY)`(<STMTS stmts>)`) = stmts2exp(stmts);

Expression stmts2exp(STMTS stmts)
  = call(function("", [], [], "", block([ stmt2js(s) | s <- stmts ])), []); 
   

Expression prim2js((PRIMARY)`<LITERAL lit>`) = 3;
Expression prim2js((PRIMARY)`<VARIABLE var>`) = var2js(var);
Expression prim2js((PRIMARY)`::<IDENTIFIER id>`) = "<id>";

Expression prim2js((PRIMARY)`[<{EXPR ","}* elts>]`) = 
   array([ expr2js(e) | e <- elts ]);
   
Expression prim2js((PRIMARY)`yield`) 
  = { throw "Yield not supported; use explicit block."; };
Expression prim2js((PRIMARY)`yield(<CALLARGS args>)`) 
  = { throw "Yield not supported; use explicit block."; };
  
Expression prim2js((PRIMARY)`yield()`)
  = { throw "Yield not supporteduse explicit block."; };
  
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

list[Pattern] defaultParams((DEFAULTS)`<{DEFAULT ","}+ ds>`)
  = [ variable("<d.id>") | d <- ds ];

list[Pattern] params({IDENTIFIER ","}+ ids) = [ variable("<i>") | i <- ids ];

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
  

  
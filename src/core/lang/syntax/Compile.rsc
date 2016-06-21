module core::lang::\syntax::Compile

import core::lang::\syntax::EnsoLanguage;
import core::lang::\syntax::JavascriptAST;
import IO;
import String;
import List;
import ParseTree;
import Message;

list[Statement] mainBody() = [
  Statement::varDecl([variableDeclarator(Pattern::variable("requirejs"), 
    Init::expression(call(Expression::variable("require"), 
          [literal(string("requirejs"))])))], "var"),
 // requirejs.config({ nodeRequire: require, baseUrl: 'js' });
    call(member(Expression::variable("requirejs"), "config"), [
           object([<id("nodeRequire"), Expression::variable("require"), "">,
                   <id("baseURL"), literal(string("js")), "">])]), 
    x];
    
    
set[Message] ERRS = {};

tuple[Program program, set[Message] msgs] compileUnit(Unit u) {
  ERRS = {};
  pushScope({"Enumerable", "Proc"});
  return <unit2js(u), ERRS>;
}

list[Statement] error(Tree t, str msg) {
  ERRS += {error(msg, t@\loc)};
  return [];
}

list[Statement] warning(Tree t, str msg) {
  ERRS += {warning(msg, t@\loc)};
  return [];
}

set[str] classesAndModules(STMTS stmts) {
  names = {"Enumerable"};
  for(STMT s <- stmts.stmts) {
    switch (s) {
      case (STMT)`class <IDENTIFIER x> <STMTS _> end`: names += {"<x>"};
      case (STMT)`module <IDENTIFIER x> <STMTS _> end`: names += {"<x>"};
      case (STMT)`class <IDENTIFIER x> <EXTEND _> <STMTS _> end`: names += {"<x>"};
    }
  }
  return names;
}

Program unit2js((Unit)`<STMTS stmts>`) {
  if ((STMT)`module <IDENTIFIER name> <STMTS body> end` <- stmts.stmts) {
    // toplevel
    ps = requiredPaths(stmts);

    pushModule();
    
    Expression func 
      = makeFunc([Pattern::variable(n) | n <- paths2modules(ps)],
                   body, 
                   [Statement::varDecl([variableDeclarator(Pattern::variable("<name>"), Init::none())], "var")],
                   list[Statement] () { // lazy
                      return [Statement::expression(assignment(assign(),
                            Expression::variable("<name>"),
                            Expression::object([<LitOrId::id(m), topModule().bindings[m], ""> 
                                | m <- topModule().bindings ]))),
                         \return(Expression::variable("<name>"))];
                   }, 
                   classesAndModules(body)
          );
    
    list[Statement] ss = 
      [Statement::expression(call(Expression::variable("define"), [
         Expression::array([ literal(string(p)) | p <- ps]),
         func
     ]))];

    popScope();
    return program(ss);
     
  }
  // TODO: do the require.js stuff.
  return program(stmts2js(stmts));
} 

// For some reason this require pattern also captures matches raise statements
// when using deep match and := body...
list[str] requiredPaths(STMTS body)
  = [ "<p>"[1..-1] | (STMT)`require <STRING p>` <- body.stmts ];

list[str] paths2modules(list[str] paths)
  = [ capitalize(split("/", p)[-1]) | p <- paths ];


list[Statement] declareModule(list[str] reqPaths, str name, STMTS body)
  = [expression(call(Expression::variable("define"), [
       array([ literal(string(p)) | p <- reqPaths]),
       function("", [Pattern::variable(n) | n <- paths2modules(reqPaths)], [], "",
         [
           varDecl(variableDeclarator(Pattern::variable(name), Init::none()), "var"),
           stmts2js(body)
         ])
     ]))];
  


// Statement lists

list[Statement] stmts2js((STMTS)`<NL* _><{STMT TERM}+ stmts><NL* _>`)
  = ( [] | it + stmt2js(s) | s <- stmts );

default list[Statement] stmts2js(STMTS _) = [];

default list[Statement] stmt2js(STMT x) = warning(x, "unhandled stmt"); 



Statement blockOrNot([Statement s]) = s;
default Statement blockOrNot(list[Statement] ss) = block(ss);

// Statements
list[Statement] stmt2js((STMT)`if <EXPR e> <THEN _> <STMTS body> <ELSIF* eifs> else <STMTS ebody> end`)
  = [\if(expr2js(e), blockOrNot(stmts2js(body)), blockOrNot(elsifs2js(eifs, stmts2js(ebody))))];

list[Statement] stmt2js((STMT)`if <EXPR e> <THEN _> <STMTS body> end`)
  = [\if(expr2js(e), blockOrNot(stmts2js(body)))];

list[Statement] stmt2js((STMT)`if <EXPR e> <THEN _> <STMTS body> <ELSIF* eifs> end`)
  = [\if(expr2js(e), blockOrNot(stmts2js(body)), blockOrNot(elsifs2js(eifs, [])))]
  when [eif | eif <- eifs] != [];


default list[Statement] elsifs2js(ELSIF* eifs, list[Statement] els) 
  = [( blockOrNot(els) | \if(expr2js(e), blockOrNot(stmts2js(b)), it) 
      | (ELSIF)`elsif <EXPR e> <THEN _> <STMTS b>` 
        <- reverse([ eif | eif <- eifs]))];
  
list[Statement] stmt2js((STMT)`unless <EXPR e> <THEN _> <STMTS body> else <STMTS ebody> end`)
  = [\if(unary(not(), true, expr2js(e)), blockOrNot(stmts2js(body)), blockOrNot(stmts2js(ebody)))];

list[Statement] stmt2js((STMT)`unless <EXPR e> <THEN _> <STMTS body>end`)
  = [\if(unary(not(), true, expr2js(e)), blockOrNot(stmts2js(body)))];

list[Statement] stmt2js((STMT)`while <EXPR e> <DO _> <STMTS body> end`)
  = [\while(expr2js(e), blockOrNot(stmts2js(body)))];

list[Statement] stmt2js((STMT)`until <EXPR e> <DO _> <STMTS body> end`)
  = [\while(unary(not(), true, expr2js(e)), blockOrNot(stmts2js(body)))];

// NOTE: these are expressions in the grammar, but here we only
// allow them as statements... (can't use ?:)
  
list[Statement] stmt2js((STMT)`<EXPR l> if <EXPR r>`) 
  = [\if(expr2js(r), Statement::expression(expr2js(l)))];
   
list[Statement] stmt2js((STMT)`<EXPR l> while <EXPR r>`) 
  = [\while(expr2js(r), Statement::expression(expr2js(l)))];
   
list[Statement] stmt2js((STMT)`<EXPR l> unless <EXPR r>`) 
  = [\if(unary(not(), true, expr2js(r)), Statement::expression(expr2js(l)))];

list[Statement] stmt2js((STMT)`<EXPR l> until <EXPR r>`) 
  = [\while(unary(not(), true, expr2js(r)), Statement::expression(expr2js(l)))];
  
str caseVar(STMT cas) = "case$<cas@\loc.offset>";

// nasty ambiguity somewhere in Rascal
list[Statement] l(Statement x) = [x];

list[Statement] stmt2js(t:(STMT)`case <STMTS stmts> <WHEN+ whens> end`)
  = l(caseStat)
  when 
     cases :=  [ switchCase(when2js(wa), [*stmts2js(cstmts), Statement::\break()]) |
       (WHEN)`when <WHEN_ARGS wa> <THEN _> <STMTS cstmts>` <- reverse([ w | w <- whens ]) ],  
     caseStat := \switch(stmts2exp(stmts), cases);


list[Statement] stmt2js(t:(STMT)`case <STMTS stmts> <WHEN+ whens> else <STMTS ebody> end`)
  = l(caseStat)
  when 
     ecase := switchCase(stmts2js(ebody)),
     cases :=  [ switchCase(when2js(wa), [*stmts2js(cstmts), Statement::\break()]) |
       (WHEN)`when <WHEN_ARGS wa> <THEN _> <STMTS cstmts>` <- reverse([ w | w <- whens ]) ],  
     caseStat := \switch(stmts2exp(stmts), [*cases, ecase]);
  

//list[Statement] stmt2js(t:(STMT)`case <STMTS stmts> <WHEN+ whens> else <STMTS ebody> end`)
//  = l(Statement::expression(call(function("", [Pattern::variable(x)], [], "", [whenStat]), [stmts2exp(stmts)])))
//  when x := caseVar(t),
//      whenStat := ( blockOrNot(stmts2js(ebody)) | \if(whenArgs2Cond(wa, x), blockOrNot(stmts2js(stmts)), it) 
//      | (WHEN)`when <WHEN_ARGS wa> <THEN _> <STMTS stmts>` <- reverse([ w | w <- whens ]) ); 
  

  
//list[Statement] stmt2js(t:(STMT)`case <STMTS stmts> <WHEN+ whens> end`)
//  = l(Statement::expression(call(function("", [Pattern::variable(x)], [], "", [whenStat]), [stmts2exp(stmts)])))
//  when x := caseVar(t),
//    whenStat := ( empty() | \if(whenArgs2Cond(wa, x), blockOrNot(stmts2js(stmts)), it) 
//      | (WHEN)`when <WHEN_ARGS wa> <THEN _> <STMTS stmts>` <- reverse([ w | w <- whens ]) ); 
  
//list[Statement] whens2js(WHEN+ whens, Statement els, str x) 
//  = l(); 


Expression when2js((WHEN_ARGS)`<EXPR e>`) = expr2js(e);

default Expression when2js(WHEN_ARGS w) {
  error(w, "Unsupported when-clause");
  return Expression::variable("UNSUPPORTED_WHEN_CLAUSE");
}


Expression whenArgs2Cond((WHEN_ARGS)`<{EXPR ","}+ es>`, str x)
  = ( literal(boolean(false))  
       | logical(or(), binary(longEquals(), Expression::variable(x), expr2js(e)), it)
       | EXPR e <- reverse([ e | e <- es ]) );

Expression whenArgs2Cond((WHEN_ARGS)`<{EXPR ","}+ es>, <STAR _> <EXPR rest>`, str x)
  = ( binary(\in(), Expression::variable(x), expr2js(rest)) 
       | logical(or(), binary(longEquals(), Expression::variable(x), expr2js(e)), it)
       | EXPR e <- reverse([ e | e <- es ]) );

Expression whenArgs2Cond((WHEN_ARGS)`<STAR _> <EXPR rest>`, str x)
  = binary(\in(), Expression::variable(x), expr2js(rest)); 

Expression whenArgs2Cond((WHEN_ARGS)``, str x)
  = literal(boolean(false)); 

list[Statement] stmt2js(s:(STMT)`for <BLOCK_VAR bv> in <EXPR e> <DO _> <STMTS stmts> end`)
  = error(s , "For-in not supported.");
 
str tryVar(STMT s) = "caught$<s@\loc.offset>";
  
list[Statement] stmt2js(t:(STMT)`begin <STMTS stmts> <RESCUE+ rescues> else <STMTS els> ensure <STMTS ens> end`)
  = l(\try(stmts2js(stmts), catchClause(Pattern::variable(x), rescues2ifs(rescues, stmts2js(els), x)), stmts2js(ens)))
  when x := tryVar(t);

list[Statement] stmt2js(t:(STMT)`begin <STMTS stmts> <RESCUE+ rescues> else <STMTS els> end`)
  = l(\try(stmts2js(stmts), catchClause(Pattern::variable(x), rescues2ifs(rescues, stmts2js(els), x))))
  when x := tryVar(t);
  
list[Statement] stmt2js(t:(STMT)`begin <STMTS stmts> <RESCUE+ rescues> ensure <STMTS ens> end`)
  = l(\try(stmts2js(stmts), catchClause(Pattern::variable(x), rescues2ifs(rescues, empty(), x)), stmts2js(ens)))
  when x := tryVar(t);
  
list[Statement] stmt2js(t:(STMT)`begin <STMTS stmts> <RESCUE+ rescues> end`)
  = l(\try(stmts2js(stmts), catchClause(Pattern::variable(x), rescues2ifs(rescues, empty(), x))))
  when x := tryVar(t);


list[Statement] rescues2ifs(RESCUE+ rescues, Statement els, str x)
  = ( els | rescue2clause(r, it, x) | r <- reverse([ r | r <- rescues ]) );

list[Statement] rescue2clause(r:(RESCUE)`rescue <DO _> <STMTS body>`, Statement els, str x)
  = stmts2js(body);


list[Statement] rescue2clause(r:(RESCUE)`rescue <EXPR e>, <{EXPR ","}* es> <DO _> <STMTS body>`, Statement els, str x)
  = error(r, "not yet implemented");

list[Statement] rescue2clause((RESCUE)`rescue <EXPR e> =\> <IDENTIFIER y> <DO _> <STMTS body>`, Statement els, str x)
  = [\if(binary(instanceOf(), Expression::variable(x), expr2js(e)),
     Statement::expression(
       call(function("", [Pattern::variable("<y>")], [], "", stmts2js(body)), 
        [Expression::variable(x)])), els)];




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
  
list[Statement] declareMixin(str name, STMTS body) {
 declareModuleBinding(name, Expression::variable(name));
 pushModule();
 mods = includedModules(body);
 //for (m <- mods) {
 //  declareModuleBinding(m, Expression::variable(m));
 //}
 ss = l(Statement::varDecl([variableDeclarator(Pattern::variable(name), 
               Init::expression(call(Expression::variable("MakeMixin"), 
                  [Expression::array(mods), 
                  Expression::function("", [], [], "", stmts2js(body))
                  ])))], "var"));
 popScope();
 return ss;
}                  
  

list[Statement] stmt2js((STMT)`module <IDENTIFIER name> <STMTS body> end`)
  = declareMixin("<name>", body);

list[Statement]() EMPTY = list[Statement]() { return []; };

list[Statement] declareClass(str name, Expression super, STMTS body) {
  declareModuleBinding(name, Expression::variable(name));
  pushModule();
  mods = includedModules(body);
  
  classStmts = classStmts2js(body);
  //println("CLS: <classStmts>");
  
  CURRENT_METHOD = "";
  ss = l(Statement::varDecl([variableDeclarator(Pattern::variable(name), 
               Init::expression(call(Expression::variable("MakeClass"), 
                  [literal(string("<name>")), 
                  super,
                  Expression::array(mods),
                  Expression::function("", [], [], "", classStmts)
                  ,
                  makeFunc([Pattern::variable("super$")], body, [], EMPTY, {})
                  ])))], "var"));
  popScope();
  return ss;               
}

list[Statement] classStmts2js(STMTS stmts) =
  ( [] | it + classStmt2js(s) | s <- stmts.stmts );
  
  
list[Statement] classStmt2js(s:(STMT)`@@<IDENTIFIER x> = <EXPR e>`)
  = [Statement::expression(assignment(assign(), 
         member(member(this(), "$"), fixFname("<x>")), 
         expr2js(e)))];
  

list[Statement] classStmt2js((STMT)`def self.<FNAMENoReserved f>(<ARGLIST args>) <STMTS body> end`) 
  = declareMethod(parse(#FNAME, "<f>"), args, body); // I'm lazy here...

list[Statement] classStmt2js((STMT)`def self.<FNAMENoReserved f> <TERM _> <STMTS body> end`) 
  = declareMethod(parse(#FNAME, "<f>"), (ARGLIST)``, body);
  
default list[Statement] classStmt2js(STMT s) = [];

list[Statement] stmt2js((STMT)`class <IDENTIFIER id> <STMTS body> end`)
  = declareClass("<id>", literal(null()), body);
  

list[Statement] stmt2js((STMT)`class <IDENTIFIER id> \< <IDENTIFIER sup> <STMTS body> end`)
  = declareClass("<id>", Expression::variable("<sup>"), body);


str fixFname(/^<name:[a-zA-Z0-9_]*>=$/) = "set_<name>";
str fixFname("[]") = "_get";
str fixFname("[]=") = "_set";
str fixFname("\<\<") = "push";
default str fixFname(str name) = fixOp(name);

//anno bool STMT@tail;
//
//STMTS annotateTailExprs(STMTS body) {
//  return bottom-up visit (body) {
//    case s:(STMT)`<EXPR e>` => s[@tail=true] 
//  }
//}

//list[Statement] addReturns([*list[core::lang::\syntax::JavascriptAST::Statement] ss, core::lang::\syntax::JavascriptAST::Statement s]) 
//  = [*ss, addReturns(s)];
//
//list[core::lang::\syntax::JavascriptAST::Statement] addReturns(list[core::lang::\syntax::JavascriptAST::Statement] xs) = []
//  when xs == [];

list[Statement] addReturns(list[Statement] ss) {
  if (ss != []) {
    return ss[0..-1] + [addReturns(ss[-1])];
  }
  return [];
}

Statement addReturns(s:Statement::expression(x)) = \return(x);
Statement addReturns(\if(x, t, e)) = \if(x, addReturns(t), addReturns(e));
Statement addReturns(\if(x, t)) = \if(x, addReturns(t));
Statement addReturns(block(ss)) = block(addReturns(ss));
Statement addReturns(Statement \try(s, h, f)) = \try(addReturns(s), addReturns(h), addReturns(f));
Statement addReturns(Statement \try(s, h)) = \try(addReturns(s), addReturns(h));
Statement addReturns(\switch(e, cs)) =
  \switch(e, [ c[consequent=addReturns(c.consequent)] | c <- cs ]); 

default Statement addReturns(Statement s) = s;

CatchClause addReturns(catchClause(p, ss)) = catchClause(p, addReturns(ss)); 


str CURRENT_METHOD = "";
Expression methodFunction__(str f, ARGLIST args, STMTS body) {
  resetAssignedVars();
  sym = fixFname(f);
  Expression func = arglist2func(sym, args);
  CURRENT_METHOD = sym;
  func.name = "";
  func.statBody = 
    [Statement::varDecl([variableDeclarator(
                Pattern::Expression::variable("self"), Init::expression(this()))
                ], "var"), *func.statBody];
                
  formals = { x | Pattern::variable(x) <- func.params };
  
  // Ugh this is ugly.                 
  ASSIGNED += formals;
  bodyStats = stmts2js(body); // NB: before we read assignedVars
  ASSIGNED -= formals;
  if (assignedVars() != {}) { 
    func.statBody += 
      [Statement::varDecl([
         variableDeclarator(Pattern::variable(a), Init::none())
                        | a <- assignedVars()], "var")];
  } 
  func.statBody += bodyStats;
  func.statBody = addReturns(func.statBody);
  return func;

}

Expression methodFunction(str f, ARGLIST args, STMTS body) {
  sym = fixFname(f);
  CURRENT_METHOD = sym;
  Expression func = arglist2func(sym, args);
  
  selfDecl = 
    [Statement::varDecl([variableDeclarator(
                Pattern::variable("self"), Init::expression(this()))
                ], "var")];
  Expression theFunc = makeFunc(func.params, body, selfDecl + func.statBody, EMPTY, {});
  CURRENT_METHOD = "";
  return theFunc;              
}

list[Statement] makeDecls(set[str] names) { 
  if (names != {}) { 
    return
      [Statement::varDecl([
         variableDeclarator(Pattern::variable(a), Init::none())
                        | a <- names], "var")];
  }
  return [];
} 


data Scope
  = modul(map[str, Expression] bindings)
  | method(set[str] vars)
  ;

list[Scope] STACK = [];

bool isDeclared(str name) = name in ( {} | it + s | method(set[str] s) <- STACK );

void pushScope() { pushScope(method({})); }
void pushScope(set[str] vars) { pushScope(method({})); }
void pushScope(Scope s) { STACK += [s]; }
void popScope() { STACK = STACK[0..-1]; }
Scope topScope() = STACK[-1];
void declareVar(str var) = declareVars({var});
void declareVars(set[str] vars) {
  newScope = method(topScope().vars + { fixVar(v) | v <- vars, !isDeclared(v) });
  popScope();
  pushScope(newScope);
}

int topModuleIndex() {
  i = size(STACK) - 1;
  while (i >= 0, !(STACK[i] is modul) ) {
    i -= 1;
  }
  return i;
}

Scope topModule() = STACK[topModuleIndex()];

void pushModule() { pushModule(()); }
void pushModule(map[str, Expression] m) { STACK += [modul(m)]; }
void declareModuleBinding(str var, Expression exp) {
  STACK[topModuleIndex()].bindings += (fixFname(var): exp);
}


//void pushScope() { pushScope({}); }
//void pushScope(set[str] vars) { STACK += [vars]; }
//void popScope() { STACK = STACK[0..-1]; }
//set[str] topScope() = STACK[-1];
//void declareVar(str var) = declareVars({var});
//void declareVars(set[str] vars) {
//  newScope = topScope() + { fixVar(v) | v <- vars, !isDeclared(v) };
//  popScope();
//  pushScope(newScope);
//}
//
//bool isDeclared(str name) = name in ( {} | it + s | set[str] s <- STACK );
//
//list[map[str, Expression]] MODULE_STACK = [];
//
//void pushModule() { pushModule(()); }
//void pushModule(map[str, Expression] m) { MODULE_STACK += [m]; }
//void popModule() { MODULE_STACK = MODULE_STACK[0..-1]; }
//map[str, Expression] topModule() = MODULE_STACK[-1];
//void declareModuleBinding(str var, Expression exp) {
//  newMod = topModule() + ( fixFname(var): exp );
//  popModule();
//  pushModule(newMod);
//  //println("MSTACK = <MODULE_STACK>");
//}



//bool isDeclared(str name) = name in ( {} | it + s | set[str] s <- STACK );


Expression makeFunc(list[Pattern] formals, STMTS body, 
					list[Statement] begin,
                    list[Statement]() end,
                    set[str] implicits) {
  pushScope();
  declareVars(implicits);
  names = { x | Pattern::variable(x) <- formals };
  declareVars(names);
  
  // this only looks one level deep, and only in begin (not
  // body, or end... (hoisting)
  decls = { x | Statement::varDecl(vds, _) <- begin, 
                variableDeclarator(Pattern:variable(x), _) <- vds };
  declareVars(decls);
  
  theStats = stmts2js(body); // declares vars
  
  set[str] getDecls(Statement::varDecl(vds, _))
    = { x | variableDeclarator(Pattern:variable(x), _) <- vds };
  
  set[str] hoist(list[Statement] stats) {
    ds = {};
    top-down-break visit (stats) {
      case Expression::function(_, _, _, _, _): ; // stop at functions
      case vs:Statement::varDecl(vds, _): ds += getDecls(vd);
    }
    return ds;
  }
  
  bool shadowed(v) =
    v in ( {} | it + s | set[str] s <- STACK[0..-1] ); 
  
  bodyStats = begin; 
  bodyStats += makeDecls({ v | v <- topScope().vars - names - decls - implicits, !shadowed(v) }); 
  bodyStats += theStats;
  bodyStats += end();
  popScope();
  return Expression::function("", formals, [], "", addReturns(bodyStats));
}


list[Statement] declareMethod(FNAME f, ARGLIST args, STMTS body) 
  = l(Statement::expression(assignment(assign(), member(this(), fixFname("<f>")), 
              methodFunction("<f>", args, body))));

list[Statement] stmt2js((STMT)`def <FNAME f>(<ARGLIST args>) <STMTS body> end`)
  = declareMethod(f, args, body); 

list[Statement] stmt2js((STMT)`def <FNAME f> <TERM _> <STMTS body> end`) 
  = declareMethod(f, (ARGLIST)``, body);


list[Statement] stmt2js((STMT)`def self.<FNAMENoReserved f>(<ARGLIST args>) <STMTS body> end`) {
  name = fixFname("<f>");
  declareModuleBinding(name,  methodFunction(name, args, body));
  return [];
}

list[Statement] stmt2js((STMT)`def self.<FNAMENoReserved f> <TERM _> <STMTS body> end`) {
  name = fixFname("<f>");
  declareModuleBinding(name, methodFunction(name, (ARGLIST)``, body));
  return [];
}

list[Statement] reader(str name)
  = l(Statement::expression(assignment(assign(), member(this(), name), 
      Expression::function("", [], [], "", [\return(member(member(this(), "$"), name))]))));

list[Statement] writer(str name)
  = l(Statement::expression(assignment(assign(), member(this(), "set_" + name), 
      Expression::function("", [Pattern::variable("val")], [], "", 
          [Statement::expression(assignment(assign(), 
             member(member(this(), "$"), name), Expression::variable("val")))]))));

// Again: matching on identifiers does not work...
list[Statement] stmt2js((STMT)`<OPERATION1 op> <CALLARGS args>`)
  = ( [] | it + reader(x) | literal(string(x)) <- exps )
  when "<op>" == "attr_reader", <_, exps> := callargs2js(args);

list[Statement] stmt2js((STMT)`<OPERATION1 op> <CALLARGS args>`)
  = ( [] | it + reader(x) + writer(x)  | literal(string(x)) <- exps )
  when "<op>" == "attr_accessor", <_, exps> := callargs2js(args);

// Collected separately when declaring a mixin.
list[Statement] stmt2js((STMT)`include <CALLARGS _>`) = [];

list[Statement] stmt2js((STMT)`<OPERATION1 op> <CALLARGS args>`)
  = [Statement::expression(makeCall(callargs2js(args), Expression::variable("self"), fixOp("<op>"), []))]
  when "<op>" notin {"attr_reader", "attr_accessor", "include"};
  //when bprintln("CA = <args>");

// ????
//list[Statement] stmt2js((STMT)`<OPERATION2 op> <CALLARGS args> <BLOCK block>`)
//  = makeCall(callargs2js(args), Expression::variable("self"), fixVar("<op>"), [block2js(block)]);

list[Statement] stmt2js(s:(STMT)`super <CALLARGS args>`)
  = error(s, "super without parent method not supported"); 
  //makeCall(callargs2js(args), Expression::variable("super$"), fixVar("<op>"), []);

list[Statement] stmt2js((STMT)`<PRIMARY p>.<OPERATION2 op> <CALLARGS args>`)
  = [Statement::expression(makeCall(callargs2js(args), prim2js(p), fixOp("<op>"), []))];

list[Statement] stmt2js((STMT)`<PRIMARY p>::<OPERATION3 op> <CALLARGS args>`)
  = [Statement::expression(makeCall(callargs2js(args), prim2js(p), fixOp("<op>"), []))];
  
list[Statement] stmt2js((STMT)`<EXPR e>`) 
  = [Statement::expression(expr2js(e))]; // when bprintln("e = <e>");

list[Statement] stmt2js((STMT)`<VARIABLE var> = <STMT s>`) {
  //println("var = <var>");
  //println("var is class: <var is class>");
  //println("Current: <CURRENT_METHOD>");
  if (var is class && CURRENT_METHOD == "") {
    return [];
  }
  return [Statement::expression(assignment(assign(), assignVar2js(var), 
          stmt2exp(s)))];
}

Expression stmt2exp((STMT)`<EXPR e>`) = exprjs(e);

default Expression stmt2exp(STMT s) 
  = stmts2exp((STMTS)`<STMT s>`);
  
list[Statement] stmt2js((STMT)`<STMT s> if <EXPR e>`)
  = [\if(expr2js(e), blockOrNot(stmt2js(s)))];
  
list[Statement] stmt2js((STMT)`<STMT s> unless <EXPR e>`)
  = [\if(unary(not(), true, expr2js(e)), blockOrNot(stmt2js(s)))];
  
list[Statement] stmt2js((STMT)`<STMT s> while <EXPR e>`)
  = [\while(expr2js(e), blockOrNot(stmt2js(s)))];
  
list[Statement] stmt2js((STMT)`<STMT s> until <EXPR e>`)
  = [\while(unary(not(), true, expr2js(e)), blockOrNot(stmt2js(s)))];
  
// Variables

str fixVar(str x) = x in 
  {"catch", "continue", "debugger", "default", "delete", 
   "finally", "function", "new", "in", "instanceof", 
   "switch", "this", "throw", "try", "typeof", "var", "void", "with"} 
  ? "<x>_V" : x;
 
str fixOp(/^<name:.*>\?$/) = "<name>_P";
str fixOp(/^<name:.*>!$/) = "<name>_C";
default str fixOp(str name) = name;
 
Expression var2js((VARIABLE)`$<IDENTIFIER id>`) =
  call(member(Expression::variable("System"), "<id>"), []); 

Expression var2js((VARIABLE)`@<IDENTIFIER id>`) 
  = member(member(Expression::variable("self"), "$"), "<id>");
  
Expression var2js((VARIABLE)`@@<IDENTIFIER id>`) 
  = member(member(member(Expression::variable("self"), "_class_"), "$"), "<id>");

Expression var2js((VARIABLE)`<IDENTIFIER id>`) 
  = Expression::variable(fixVar("<id>"));
  
  
Expression expr2js((EXPR)`<PRIMARY p>`) {
  //rprintln(p);
  return prim2js(p) ;
}
Expression expr2js((EXPR)`!<EXPR e>`) = unary(not(), true, expr2js(e));
Expression expr2js((EXPR)`~<EXPR e>`) = unary(bitNot(), true, expr2js(e));
Expression expr2js((EXPR)`+<EXPR e>`) = unary(UnaryOperator::plus(), true, expr2js(e));
Expression expr2js((EXPR)`-<EXPR e>`) = unary(UnaryOperator::min(), true, expr2js(e));
Expression expr2js((EXPR)`not <EXPR e>`) = unary(UnaryOperator::not(), true, expr2js(e));

Expression expr2js((EXPR)`<EXPR l> ** <EXPR r>`) 
  = call(member(Expression::variable("Math"), "pow"), [expr2js(l), expr2js(r)]);

Expression expr2js((EXPR)`<EXPR l> * <EXPR r>`) = binary(times(), expr2js(l), expr2js(r));
Expression expr2js((EXPR)`<EXPR l> / <EXPR r>`) = binary(div(), expr2js(l), expr2js(r));
Expression expr2js((EXPR)`<EXPR l> % <EXPR r>`) = binary(rem(), expr2js(l), expr2js(r));
Expression expr2js((EXPR)`<EXPR l> + <EXPR r>`) = binary(BinaryOperator::plus(), expr2js(l), expr2js(r));
Expression expr2js((EXPR)`<EXPR l> - <EXPR r>`) = binary(BinaryOperator::min(), expr2js(l), expr2js(r));

// TODO these three should not be supported
Expression expr2js((EXPR)`<EXPR l> & <EXPR r>`) = binary(bitAnd(), expr2js(l), expr2js(r));
Expression expr2js((EXPR)`<EXPR l> | <EXPR r>`) = binary(bitOr(), expr2js(l), expr2js(r));
Expression expr2js((EXPR)`<EXPR l> ^ <EXPR r>`) = binary(bitXor(), expr2js(l), expr2js(r));

Expression expr2js((EXPR)`<EXPR l> == <EXPR r>`) = binary(equals(), expr2js(l), expr2js(r));
Expression expr2js((EXPR)`<EXPR l> === <EXPR r>`) = { throw "Unsupported: ==="; };
Expression expr2js((EXPR)`<EXPR l> != <EXPR r>`) = binary(notEquals(), expr2js(l), expr2js(r));

Expression expr2js((EXPR)`<EXPR l> =~ <EXPR r>`) = call(member(expr2js(l), "match"), [expr2js(r)]);
Expression expr2js((EXPR)`<EXPR l> !~ <EXPR r>`) = unary(not(), true, call(member(expr2js(l), "match"), [expr2js(r)]));
Expression expr2js((EXPR)`<EXPR l> && <EXPR r>`) = logical(and(), expr2js(l), expr2js(r));
Expression expr2js((EXPR)`<EXPR l> || <EXPR r>`) = logical(or(), expr2js(l), expr2js(r));

Expression expr2js((EXPR)`<EXPR l> .. <EXPR r>`)
  = call(member(Expression::variable("Range"), "new"), [expr2js(l), expr2js(r)]); 

Expression expr2js((EXPR)`<EXPR l> ... <EXPR r>`) = { throw "Unsupported: ..."; };

Expression expr2js((EXPR)`<EXPR l> and <EXPR r>`) = logical(and(), expr2js(l), expr2js(r));
Expression expr2js((EXPR)`<EXPR l> or <EXPR r>`) = logical(or(), expr2js(l), expr2js(r));


Expression expr2js((EXPR)`<EXPR c> ? <EXPR t> : <EXPR e>`) 
  =  conditional(expr2js(c), expr2js(t), expr2js(e));

Expression expr2js((EXPR)`<VARIABLE v> = <EXPR r>`) {
  if (v is class && CURRENT_METHOD == "") {
    return undefined();
  }
  return assignment(assign(), assignVar2js(v), expr2js(r));
}
  
Expression expr2js((EXPR)`<PRIMARY p>[<EXPR e>] = <EXPR r>`)  
  = call(member(prim2js(p), "_set"), [expr2js(e), expr2js(r)]);
  //assignment(assign(), member(prim2js(p), expr2js(e)), expr2js(r));
  
Expression expr2js((EXPR)`<PRIMARY p>.<IDENTIFIER x> = <EXPR r>`)  
  //= assignment(assign(), member(prim2js(p), "<x>"), expr2js(r));
  = call(member(prim2js(p), fixFname("<x>=")), [expr2js(r)]);
  
Expression expr2js((EXPR)`<VARIABLE v> **= <EXPR r>`)
  = assignment(assign(), ve, 
       call(member(Expression::variable("Math"), "power"), ve, expr2js(r)))
  when ve := assignVar2js(v);

Expression expr2js((EXPR)`<VARIABLE v> &&= <EXPR r>`)
  = assignment(assign(), ve, logical(and(), ve, expr2js(r)))
  when ve := assignVar2js(v);
   
Expression expr2js((EXPR)`<VARIABLE v> ||= <EXPR r>`)
  = assignment(assign(), ve, logical(or(), ve, expr2js(r)))
  when ve := assignVar2js(v);

default Expression expr2js((EXPR)`<VARIABLE v> <OP_ASGN op> <EXPR r>`) {
  //println("v = <v>");
  //println("r = <r>");
  //println("CURRENT: <CURRENT_METHOD>");
  //println("v is class == <v is class>");
  if (v is class && CURRENT_METHOD == "") {
    return undefined();
  }
  return assignment(assignOp(op), assignVar2js(v), expr2js(r));
}

Expression assignVar2js(v:(VARIABLE)`<IDENTIFIER x>`) {
  n = "<x>";
  //if (!isDeclared(n)) {
  declareVar(n);
  //}
  return var2js(v);
}

default Expression assignVar2js(VARIABLE v) = var2js(v); 

AssignmentOperator assignOp((OP_ASGN)`+=`) = plusAssign();
AssignmentOperator assignOp((OP_ASGN)`-=`) = minAssign();
AssignmentOperator assignOp((OP_ASGN)`*=`) = timesAssign();
AssignmentOperator assignOp((OP_ASGN)`/=`) = divAssign();
AssignmentOperator assignOp((OP_ASGN)`%=`) = remAssign();
AssignmentOperator assignOp((OP_ASGN)`&=`) = bitAndAssign();
AssignmentOperator assignOp((OP_ASGN)`|=`) = bitOrAssign();
AssignmentOperator assignOp((OP_ASGN)`^=`) = bitXorAssign();
AssignmentOperator assignOp((OP_ASGN)`\<\<=`) = bitShiftLeftAssign();
AssignmentOperator assignOp((OP_ASGN)`\>\>=`) = bitShiftRightAssign();
AssignmentOperator assignOp((OP_ASGN)`**=`) = assign();
AssignmentOperator assignOp((OP_ASGN)`&&=`) = assign();
AssignmentOperator assignOp((OP_ASGN)`||=`) = assign();

Expression prim2js((PRIMARY)`nil`) = literal(null());
Expression prim2js((PRIMARY)`self`) = Expression::variable("self");
Expression prim2js((PRIMARY)`true`) = literal(boolean(true));
Expression prim2js((PRIMARY)`false`) = literal(boolean(false));

Expression prim2js((PRIMARY)`(<NL* _><EXPR e><NL* _>)`) 
  = expr2js(e);

Expression prim2js((PRIMARY)`(<NL* _><STMT s><NL* _>)`) 
  = stmt2exp(s);


Expression prim2js((PRIMARY)`(<NL* n1><STMT s><TERM t><{STMT TERM}+ ss><NL* n2>)`) 
  = stmts2exp((STMTS)`<NL* n1><STMT s><TERM t><{STMT TERM}+ ss><NL* n2>`);


Expression stmts2exp((STMTS)`<IDENTIFIER op> <CALLARGS args>`) 
  = expr2js((EXPR)`<IDENTIFIER op>(<CALLARGS args>)`);

Expression stmts2exp((STMTS)`<PRIMARY p>.<IDENTIFIER op> <CALLARGS args>`) 
  = expr2js((EXPR)`<PRIMARY p>.<IDENTIFIER op>(<CALLARGS args>)`);

Expression stmts2exp((STMTS)`<PRIMARY p>::<IDENTIFIER op> <CALLARGS args>`) 
  = expr2js((EXPR)`<PRIMARY p>::<IDENTIFIER op>(<CALLARGS args>)`);

Expression stmts2exp((STMTS)`<EXPR e>`) = expr2js(e);

default Expression stmts2exp(STMTS stmts)
  = call(Expression::function("", [], [], "", 
       addReturns(( [] | it + stmt2js(s) | s <- stmts.stmts ))), []); 
   

Expression prim2js((PRIMARY)`<LITERAL lit>`) =lit2js(lit);
Expression prim2js((PRIMARY)`<VARIABLE var>`) = var2js(var);
Expression prim2js((PRIMARY)`::<IDENTIFIER id>`) = fixVar("<id>");

Expression lit2js((LITERAL)`<STRING s>`) = str2js(s);
Expression lit2js((LITERAL)`<SYMBOL s>`) = literal(string("<s>"[1..]));

Expression lit2js((LITERAL)`<Numeric s>`) = literal(number(toInt("<s>")))
  when /^[0-9]+$/ := "<s>";
  
Expression lit2js((LITERAL)`<Numeric s>`) = literal(number(toReal("<s>")))
  when /^[0-9]+\.[0-9]+$/ := "<s>";
  
  
str unescape(str x) = x; 
  //= escape(x, ("\\\"": "\"", "\\\'": "\'", 
  //             "\\n": "\n", "\\t": "\t", "\\r": "\r"));

Expression str2js((STRING)`<SSTR s>`) = literal(string(unescape("<s>"[1..-1])));
Expression str2js((STRING)`<ISTR s>`) = literal(string(unescape("<s>"[1..-1])));

Expression str2js((STRING)`<BSTR s><TAIL t>`) 
  = call(Expression::variable("S"), 
      [literal(string(unescape("<s>"[1..-2]))), *tail2js(t)]);
      
list[Expression] tail2js((TAIL)`<EXPR e><MSTR s><TAIL t>`)
  = [expr2js(e), literal(string(unescape("<s>"[1..-2]))), *tail2js(t)];

list[Expression] tail2js((TAIL)`<EXPR e><ESTR s>`)
  = [expr2js(e), literal(string(unescape("<s>"[1..-1])))];



Expression prim2js((PRIMARY)`[<{EXPR ","}* elts>]`) = 
   Expression::array([ expr2js(e) | e <- elts ]);
   
Expression prim2js((PRIMARY)`yield`) 
  = { throw "Yield not supported; use explicit block."; };
Expression prim2js((PRIMARY)`yield(<CALLARGS args>)`) 
  = { throw "Yield not supported; use explicit block."; };
Expression prim2js((PRIMARY)`yield()`)
  = { throw "Yield not supporteduse explicit block."; };
  
Expression makeCall(<bool apply, list[Expression] args>, Expression trg, str name, list[Expression] blockIfAny) {
  switch (<apply, name>) {
    case <false, "call">: 
      return call(trg, blockIfAny + args);
    case <false, _>:
      return call(member(trg, name), blockIfAny + args); 
    case <true, "call">:
      return call(member(trg, "apply"), [trg, *blockIfAny, *args]);
    case <true, _>:
      return call(member(member(trg, name), "apply"), [trg, *blockIfAny, *args]); 
  }
}


// NOTE: assume if block is given, there is &block argument in CALLARGS.
 
Expression prim2js((PRIMARY)`<OPERATION op>`) {
  v = fixVar("<op>");
  //println("V = <v>");
  //println("vars = <assignedVars()>");
  if (isDeclared(v)) {
     return Expression::variable(fixVar("<op>"));
  }
  //println("not in assigned vars");
  // fixOp???
  return //Expression::variable(fixVar("<op>")); 
    makeCall(<false, []>, Expression::variable("self"), fixOp("<op>"), []); 
}
  
Expression prim2js((PRIMARY)`<OPERATION op> <BLOCK block>`)  
  = makeCall(<false, []>, Expression::variable("self"), fixOp("<op>"), [block2js(block)]);
  

Expression prim2js((PRIMARY)`<POPERATION1 op>()`) 
  = makeCall(<false, []>, Expression::variable("self"), fixOp("<op>"), []);

Expression prim2js((PRIMARY)`<POPERATION2 op>() <BLOCK block>`) 
  = makeCall(<false, []>, Expression::variable("self"), fixOp("<op>"), [block2js(block)]);

Expression prim2js((PRIMARY)`<POPERATION1 op>(<CALLARGS args>)`) 
  = makeCall(callargs2js(args), Expression::variable("self"), fixOp("<op>"), []);

Expression prim2js((PRIMARY)`<POPERATION2 op>(<CALLARGS args>) <BLOCK block>`) 
  = makeCall(callargs2js(args), Expression::variable("self"), fixOp("<op>"), [block2js(block)]);
  //when bprintln("CALLARGS: <args>");

Expression prim2js((PRIMARY)`<PRIMARY p>[<{EXPR ","}* es>]`) 
  = makeCall(<false, [ expr2js(e) | e <- es]>, prim2js(p), "_get", []);


Expression prim2js((PRIMARY)`<PRIMARY p>.nil?`)
  = binary(equals(), prim2js(p), literal(null()));

Expression prim2js((PRIMARY)`<PRIMARY p>.<POPERATION3 op>(<CALLARGS args>)`)
  = call( 
      member(Expression::variable("System"), "test_type"),
      [prim2js(p), *jargs])
  when "<op>" == "is_a?", // matching doesn't work ... 
     <_, jargs> := callargs2js(args);
   

bool isSpecialOp(str op) = op in { "is_a?", "nil?" };

Expression prim2js((PRIMARY)`<PRIMARY p>.<OPERATIONNoReserved op>`)
  = makeCall(<false, []>, prim2js(p), fixOp("<op>"), [])
  when !isSpecialOp("<op>");

Expression prim2js((PRIMARY)`<PRIMARY p>::<OPERATIONNoReserved op>`) 
  = member(prim2js(p), fixVar("<op>"));
//  = makeCall(<false, []>, prim2js(p), "<op>", []);

Expression prim2js((PRIMARY)`<PRIMARY p>.<OPERATIONNoReserved op> <BLOCK b>`)
  = makeCall(<false, []>, prim2js(p), fixOp("<op>"), [block2js(b)])
  when !isSpecialOp("<op>");

Expression prim2js((PRIMARY)`<PRIMARY p>::<OPERATIONNoReserved op> <BLOCK b>`)
  = makeCall(<false, []>, prim2js(p), fixOp("<op>"), [block2js(b)]);
  

Expression prim2js((PRIMARY)`<PRIMARY p>.<POPERATION3 op>(<CALLARGS args>)`)
  = makeCall(callargs2js(args), prim2js(p), fixOp("<op>"), [])
    when !isSpecialOp("<op>");
  

// TODO: self should not be passed as first arg
Expression prim2js((PRIMARY)`<PRIMARY p>::<POPERATION4 op>(<CALLARGS args>)`)
  = makeCall(callargs2js(args), prim2js(p), fixOp("<op>"), []);

Expression prim2js((PRIMARY)`<PRIMARY p>.<POPERATION3 op>()`)
  = makeCall(<false, []>, prim2js(p), fixOp("<op>"), [])
  when !isSpecialOp("<op>");

// TODO: self should not be passed as first arg
Expression prim2js((PRIMARY)`<PRIMARY p>::<POPERATION4 op>()`)
  = makeCall(<false, []>, prim2js(p), fixOp("<op>"), []);

Expression prim2js((PRIMARY)`<PRIMARY p>.<POPERATION5 op>(<CALLARGS args>) <BLOCK b>`)
  = makeCall(callargs2js(args), prim2js(p), fixOp("<op>"), [block2js(b)])
    when !isSpecialOp("<op>");
  

// TODO: self should not be passed as first arg
Expression prim2js((PRIMARY)`<PRIMARY p>::<POPERATION6 op>(<CALLARGS args>) <BLOCK b>`)
  = makeCall(callargs2js(args), prim2js(p), fixOp("<op>"), [block2js(b)]);

Expression prim2js((PRIMARY)`<PRIMARY p>.<POPERATION5 op>() <BLOCK b>`)
  = makeCall(<false, []>, prim2js(p), fixOp("<op>"), [block2js(b)]);

// TODO: self should not be passed as first arg
Expression prim2js((PRIMARY)`<PRIMARY p>::<POPERATION6 op>() <BLOCK b>`)
  = makeCall(<false, []>, prim2js(p), fixOp("<op>"), [block2js(b)]);


Expression prim2js((PRIMARY)`super`) = Expression::variable("super$");

Expression prim2js(p:(PRIMARY)`super(<CALLARGS args>)`) 
  = call(member(member(Expression::variable("super$"), CURRENT_METHOD), "call"), 
           [Expression::variable("self"), *exps])
  when <false, exps> := callargs2js(args);

Expression prim2js(p:(PRIMARY)`super(<CALLARGS args>)`) 
  = call(member(member(Expression::variable("super$"), CURRENT_METHOD), "apply"), 
        [Expression::variable("self"), *exps])
  when <true, exps> := callargs2js(args);

  
Expression prim2js(p:(PRIMARY)`super()`) 
  = call(member(member(Expression::variable("super$"), CURRENT_METHOD), "call"), 
               [Expression::variable("self")]);   

Expression prim2js((PRIMARY)`{<{NameValuePair ","}* kvs>}`) = 
  new(Expression::variable("EnsoHash"), [Expression::object(ps)])
  when ps := [ <id("<k>"), expr2js(v) , ""> | (NameValuePair)`<IDENTIFIER k>: <EXPR v>` <- kvs ];


tuple[str, EXPR] destructure((NameValuePair)`<IDENTIFIER k>: <EXPR v>`) = <"<k>", v>;
tuple[str, EXPR] destructure((NameValuePair)`<EXPR k> =\> <EXPR v>`) = <"<k>", v>;
 

Expression block2closure(BLOCK_VAR bv, STMTS body) {
  f = blockvar2func(bv);
  return makeFunc(f.params, body, f.statBody, EMPTY, {});
}

Expression block2js((BLOCK)`{<STMTS stmts>}`) = 
  block2closure((BLOCK_VAR)``, stmts);

Expression block2js((BLOCK)`do <STMTS stmts> end`) = 
  block2closure((BLOCK_VAR)``, stmts);

Expression block2js((BLOCK)`{ |<BLOCK_VAR bv>| <STMTS stmts>}`) = 
  block2closure(bv, stmts);

Expression block2js((BLOCK)`do |<BLOCK_VAR bv>| <STMTS stmts> end`) = 
  block2closure(bv, stmts);


Expression blockvar2func((BLOCK_VAR)`<LHS v>`) 
  = Expression::function("", [lhs2pattern(v)], [], "", []);

Expression blockvar2func((BLOCK_VAR)`<LHS l1>, <{MLHS_ITEM ","}+ ms>`) 
  = Expression::function("", 
      [lhs2pattern(l1), *[ lhs2pattern(l2) | (MLHS_ITEM)`<LHS l2>` <- ms ]],
      [], "", []);

Expression blockvar2func((BLOCK_VAR)`<LHS l1>, <{MLHS_ITEM ","}+ ms>, <STAR _> <IDENTIFIER r>`) 
  = Expression::function("", 
       [lhs2pattern(l1), *[ lhs2pattern(l2) | (MLHS_ITEM)`<LHS l2>` <- ms ]],
       [], "", initAnonRestParam("<r>", pos))
 when pos := size([ m | m <- ms]) + 1; 

Expression blockvar2func((BLOCK_VAR)`<STAR _> <IDENTIFIER r>`) 
  = Expression::function("", [], [], "", initAnonRestParam("<r>", 0));
  
list[Statement] initAnonRestParam(str name, int pos)
  = [Statement::varDecl([
                  variableDeclarator(Pattern::variable(name), 
                      Init::expression(
                         call(Expression::variable("compute_rest_arguments"), [
                                Expression::variable("arguments"),
                                literal(number(pos))])))], "var")];
  
Expression blockvar2func((BLOCK_VAR)``) = 
  Expression::function("", [], [], "", []);

default Expression blockvar2func(BLOCK_VAR x) = 
  { throw "Unsupported blockvar <x>."; };

Pattern lhs2pattern((LHS)`<IDENTIFIER v>`) = Pattern::variable(fixVar("<v>"));
default Pattern lhs2pattern(LHS x) = { throw "LHS <x> not supported."; };


Expression keywords2obj((KEYWORDS)`<{KEYWORD ","}+ kws>`)
  =  new(Expression::variable("EnsoHash"), [obj])
  when obj := 
    object([<id("<k>"), expr2js(v), ""> | (KEYWORD)`<IDENTIFIER k>: <EXPR v>` <- kws]);

Expression cexpr2js((CEXPR)`<EXPR e>`) = expr2js(e);

tuple[bool, list[Expression]] callargs2js((CALLARGS)`<{CEXPR ","}+ args>, <KEYWORDS kws>, <STAR _><EXPR s>, <AMP _><EXPR b>`)
  = <true, [Expression::variable("self"), 
      call(member(array([expr2js(b), keywords2obj(kws)] + [ cexpr2js(a) | a <- args ]), "concat"), 
               [expr2js(s)])]>;

tuple[bool, list[Expression]] callargs2js((CALLARGS)`<{CEXPR ","}+ args>, <KEYWORDS kws>, <STAR _><EXPR s>`)
  = <true, [Expression::variable("self"),  
      call(member(Expression::array([ cexpr2js(a) | a <- args ] + [keywords2obj(kws)]), "concat"), 
               [expr2js(s)])]>;

tuple[bool, list[Expression]] callargs2js((CALLARGS)`<{CEXPR ","}+ args>, <KEYWORDS kws>`)
  = <false, [//Expression::variable("self"), 
             *[ cexpr2js(a) | a <- args ], keywords2obj(kws)]>;

tuple[bool, list[Expression]] callargs2js((CALLARGS)`<{CEXPR ","}+ args>, <STAR _><EXPR s>, <AMP _><EXPR b>`)
  = <true, [//Expression::variable("self"),  
      call(member(Expression::array([expr2js(b)] + [ cexpr2js(a) | a <- args ]), "concat"), 
               [expr2js(s)])]>;

tuple[bool, list[Expression]] callargs2js((CALLARGS)`<{CEXPR ","}+ args>, <STAR _><EXPR s>`)
  = <true, [//Expression::variable("self"), 
      call(member(Expression::array([ cexpr2js(a) | a <- args ]), "concat"), 
               [expr2js(s)])]>;

tuple[bool, list[Expression]] callargs2js((CALLARGS)`<{CEXPR ","}+ args>, <AMP _><EXPR b>`)
  = <false, [ expr2js(b) ] + [ cexpr2js(a) | a <- args ]>;

tuple[bool, list[Expression]] callargs2js((CALLARGS)`<{CEXPR ","}+ args>`)
  = <false, [ cexpr2js(e) | e <- args ]>;

tuple[bool, list[Expression]] callargs2js((CALLARGS)`<KEYWORDS kws>, <STAR _><EXPR s>, <AMP _><EXPR b>`)
  = <true, [//Expression::variable("self"),  
      call(member(Expression::array([expr2js(b), keywords2obj(kws)]), "concat"), 
               [expr2js(s)])]>;
               
  
tuple[bool, list[Expression]] callargs2js((CALLARGS)`<KEYWORDS kws>, <STAR _><EXPR s>`)
  = <true, [/*Expression::variable("self"),*/ call(member(Expression::array([keywords2obj(kws)]), "concat"), [expr2js(s)])]>;  

tuple[bool, list[Expression]] callargs2js((CALLARGS)`<KEYWORDS kws>`)
  = <false, [keywords2obj(kws)]>;

tuple[bool, list[Expression]] callargs2js((CALLARGS)`<STAR _><EXPR s>, <AMP _><EXPR b>`)
  = <true, [/*Expression::variable("self"),*/ call(member(Expression::array([expr2js(b)]), "concat"), [expr2js(s)])]>;

tuple[bool, list[Expression]] callargs2js((CALLARGS)`<STAR _><EXPR s>`)
  = <true, [/*Expression::variable("self"),*/ expr2js(s)]>;

tuple[bool, list[Expression]] callargs2js((CALLARGS)`<AMP _><EXPR b>`)
  = <false, [expr2js(b)]>;



// http://stackoverflow.com/questions/894860/set-a-default-parameter-value-for-a-javascript-function
//  a = typeof a !== 'undefined' ? a : 42;
//   b = typeof b !== 'undefined' ? b : 'default_b';
   

list[Statement] defaultInits((DEFAULTS)`<{DEFAULT ","}+ ds>`)
  = [ Statement::expression(assignment(assign(), Expression::variable("<d.id>"), 
        conditional(binary(longNotEquals(), unary(typeOf(), true, Expression::variable(fixVar("<d.id>"))),
          literal(string("undefined"))), Expression::variable(fixVar("<d.id>")), 
            expr2js(d.expr)))) | d <- ds ];

list[Pattern] defaultParams((DEFAULTS)`<{DEFAULT ","}+ ds>`)
  = [ Pattern::variable("<d.id>") | d <- ds ];

// BUG:
//list[Pattern] params({IDENTIFIER ","}+ ids) = [ Expression::variable("<i>") | i <- ids ];
list[Pattern] params(list[IDENTIFIER] ids) = [ Pattern::variable(fixVar("<i>")) | i <- ids ];

// Rest params: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/rest_parameters
//  var args = Array.prototype.slice.call(arguments, f.length);

list[Statement] restInits(str f, IDENTIFIER rest)
  = [ Statement::varDecl( [ variableDeclarator(Pattern::variable("<rest>"), Init::expression(e)) ], "var") ]
  when 
    e :=  call(member(member(member(Expression::variable("Array"), "prototype"), "slice"), "call"), 
             [Expression::variable("arguments"), member(member(this(), f), "length")]);
  


Expression arglist2func(str f, (ARGLIST)`<{IDENTIFIER ","}+ ids>, <DEFAULTS defs>, <STAR _> <IDENTIFIER rest>, <AMP _> <IDENTIFIER b>`) 
  = Expression::function(f, params([b]) + params([ i | i <- ids]) + defaultParams(defs), [], "", 
      defaultInits(defs) + restInits(f, rest));
  
Expression arglist2func(str f, (ARGLIST)`<{IDENTIFIER ","}+ ids>, <DEFAULTS defs>, <STAR _> <IDENTIFIER rest>`) 
  = Expression::function(f, params([ i | i <- ids]) + defaultParams(defs), [], "", 
      defaultInits(defs) + restInits(f, rest));

Expression arglist2func(str f, (ARGLIST)`<{IDENTIFIER ","}+ ids>, <DEFAULTS defs>, <AMP _> <IDENTIFIER b>`)
  = Expression::function(f, params([b]) + params([ i | i <- ids]) + defaultParams(defs), [], "", 
      defaultInits(defs));

Expression arglist2func(str f, (ARGLIST)`<{IDENTIFIER ","}+ ids>, <DEFAULTS defs>`) 
  = Expression::function(f, params([ i | i <- ids]) + defaultParams(defs), [], "", 
      defaultInits(defs));

Expression arglist2func(str f, (ARGLIST)`<{IDENTIFIER ","}+ ids>, <STAR _> <IDENTIFIER rest>, <AMP _> <IDENTIFIER b>`)
  = Expression::function(f, params([b]) + params([ i | i <- ids]), [], "", restInits(f, rest));

Expression arglist2func(str f, (ARGLIST)`<{IDENTIFIER ","}+ ids>, <STAR _> <IDENTIFIER rest>`)
  = Expression::function(f, params([ i | i <- ids]), [], "", 
      restInits(f, rest));

Expression arglist2func(str f, (ARGLIST)`<{IDENTIFIER ","}+ ids>, <AMP _> <IDENTIFIER b>`)
  = Expression::function(f, params([b]) + params([ i | i <- ids]), [], "", []);

Expression arglist2func(str f, (ARGLIST)`<{IDENTIFIER ","}+ ids>`)
  = Expression::function(f, params([ i | i <- ids]), [], "", []);

Expression arglist2func(str f, (ARGLIST)`<DEFAULTS defs>, <STAR _> <IDENTIFIER rest>, <AMP _> <IDENTIFIER b>`)
  = Expression::function(f, params([b]) + defaultParams(defs), [], "", 
      defaultInits(defs) + restInits(f, rest));

Expression arglist2func(str f, (ARGLIST)`<DEFAULTS defs>, <STAR _> <IDENTIFIER rest>`)
  = Expression::function(f, [defaultParams(defs)], [], "", 
      defaultInits(defs) + restInits(f, rest));

Expression arglist2func(str f, (ARGLIST)`<DEFAULTS defs>, <AMP _> <IDENTIFIER b>`)
  = Expression::function(f, params([b]) + defaultParams(defs), [], "", 
      defaultInits(defs));
  
Expression arglist2func(str f, (ARGLIST)`<DEFAULTS defs>`) 
  = Expression::function(f, defaultParams(defs), [], "", 
      defaultInits(defs));

Expression arglist2func(str f, (ARGLIST)`<STAR _> <IDENTIFIER rest>, <AMP _> <IDENTIFIER b>`)
  = Expression::function(f, params([b]), [], "", 
      restInits(f, rest));

Expression arglist2func(str f, (ARGLIST)`<STAR _> <IDENTIFIER rest>`) 
  = Expression::function(f, [], [], "", restInits(f, rest));

Expression arglist2func(str f, (ARGLIST)`<AMP _> <IDENTIFIER b>`)
  = Expression::function(f, params([b]), [], "", []);

Expression arglist2func(str f, (ARGLIST)``)
  = Expression::function(f, [], [], "", []);




// < and > stuff at the end...
Expression expr2js((EXPR)`<EXPR l> \<=\> <EXPR r>`) =
  conditional(binary(lt(), l1, r1), literal(number(-1)),
    conditional(binary(gt(), l1, r1), literal(number(1)), literal(number(0))))
  when l1 := expr2js(l), r1 := expr2js(r); 


Expression expr2js((EXPR)`<EXPR l> \>= <EXPR r>`) = binary(geq(), expr2js(l), expr2js(r));
Expression expr2js((EXPR)`<EXPR l> \<= <EXPR r>`) = binary(leq(), expr2js(l), expr2js(r));
Expression expr2js((EXPR)`<EXPR l> \> <EXPR r>`) = binary(gt(), expr2js(l), expr2js(r));
Expression expr2js((EXPR)`<EXPR l> \< <EXPR r>`) = binary(lt(), expr2js(l), expr2js(r));
Expression expr2js((EXPR)`<EXPR l> \<\< <EXPR r>`) = call(member(expr2js(l), "push"), [expr2js(r)]);
Expression expr2js((EXPR)`<EXPR l> \>\> <EXPR r>`) = binary(shiftRight(), expr2js(l), expr2js(r));
  

  
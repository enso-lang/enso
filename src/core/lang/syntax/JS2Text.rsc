module core::lang::\syntax::JS2Text

import core::lang::\syntax::JavascriptAST;
import List;
import IO;

data Program
  = program(list[Statement] stats)
  ;

str js2txt(program(ss)) = intercalate("\n", [ js2txt(s) | s <- ss ]);


str js2txt(ForInit::varDecl(decls, kind)) 
  = "<kind> <intercalate(",", [ js2txt(d) | d <- decls ])>";

str js2txt(ForInit::expression(e)) = js2txt(e); 

str js2txt(ForInit::none()) = ""; 

str js2txt(Init::expression(e)) = js2txt(e); 
str js2txt(Init::none()) = ""; 


str js2txt(empty()) = ";";
str js2txt(block(list[Statement] stats)) 
  = "{<for (s <- stats) {>
    '  <js2txt(s)><}>
    '}";
    
str js2txt(Statement::expression(Expression exp)) = "<js2txt(exp)>;";

str js2txt(\if(Expression \test, Statement consequent, Statement alternate)) 
  = "if (<js2txt(\test)>) <js2txt(consequent)> else <js2txt(alternate)>";
  
str js2txt(\if(Expression \test, Statement consequent)) 
  = "if (<js2txt(\test)>) <js2txt(consequent)>";

str js2txt(labeled(str label, Statement statBody)) = "<label>: <js2txt(statBody)>";
str js2txt(\break("")) = "break;";
str js2txt(\break(label)) = "break <label>;" when label != "";

str js2txt(\continue("")) = "continue;";
str js2txt(\continue(label)) = "continue <label>;";

  
str js2txt(with(Expression object, Statement statBody)) = "with {<js2txt(statBody)>}";

str js2txt(\switch(Expression discriminant, list[SwitchCase] cases, bool \lexical)) 
  = "switch (<js2txt(discriminant)>) {
    ' <for (c <- cases) {><js2txt(c)>
    ' <}>
    '}
    ";

str js2txt(\return(Expression argument)) = "return <js2txt(argument)>;";
str js2txt(\return()) = "return;";

str js2txt(\throw(Expression argument)) = "throw <js2txt(argument)>";
  
str js2txt(\try(Statement block, CatchClause handler, Statement finalizer))
  = "try {
    '  <js2txt(block)>
    '}
    '<js2txt(handler)>
    'finally {
    '  <js2txt(finalize)>
    '}";
     
str js2txt(\try(Statement block, CatchClause handler)) 
  = "try {
    '  <js2txt(block)>
    '}
    '<js2txt(handler)>";


str js2txt(\while(Expression \test, Statement statBody)) 
  = "while (<js2txt(\test)>) <js2txt(statBody)>";
  
str js2txt(doWhile(Statement statBody, Expression \test)) 
  = "do <js2txt(statBody)> while (<js2txt(\test)>)";

//str js2txt(\for(ForInit init, list[Expression] exps, Statement statBody)) = ""; // exps contains test, update
//str js2txt(forIn(list[VariableDeclarator] decls, str kind, Expression right, Statement statBody)) = "";  
//str js2txt(forIn(Expression left, Expression right, Statement statBody)) = "";
//str js2txt(forOf(list[VariableDeclarator] decls, str kind, Expression right, Statement statBody)) = "";  
//str js2txt(forOf(Expression left, Expression right, Statement statBody)) = "";
//str js2txt(let(list[tuple[Pattern id, Init init]] bindings, Statement statBody)) = "";
//str js2txt(debugger()) = "";  

str js2txt(functionDecl(str id, list[Pattern] params, 
  		list[Expression] defaults,
  		str rest, // "" = null
  		Statement statBody)) 
  = "function <id>(<intercalate(", ", [ js2txt(p) | p <- params ])>) {
    '  <js2txt(statBody)>
    '}";    
  
str js2txt(functionDecl(str id, list[Pattern] params, 
  		list[Expression] defaults,
  		str rest, // "" = null
  		Expression expBody)) 
  = "function <id>(<intercalate(", ", [ js2txt(p) | p <- params ])>) {
    '  <js2txt(expBody)>
    '}";    

str js2txt(Statement::varDecl(list[VariableDeclarator] declarations, str kind)) 
  = "<kind> <intercalate(", ", [ js2txt(d) | d <- declarations ])>;";

/*
expression(Expression exp)
  | none(
  */

str js2txt(variableDeclarator(Pattern id, Init init)) 
  = "<id.name><init == none() ? "" : " = <js2txt(init.exp)>">";

str js2txt(id(str name)) = "";
str js2txt(lit(Literal \value)) = "";

str js2txt(this()) = "this";
str js2txt(Expression::array(list[Expression] elements)) 
  = "[<intercalate(", ", [ js2txt(e) | e <- elements ])>]";

str js2txt(Expression::object(list[tuple[LitOrId key, Expression \value, str kind]] properties)) 
  = "{<intercalate(", ", [ "<js2txt(k)>: <js2txt(v)>" | <k, v, _> <- properties])>}";
    
str js2txt(Expression::function(str name, // "" = null 
            list[Pattern] params, 
            list[Expression] defaults,
            str rest, // "" = null
            Statement statBody)) 
 = "function <name>(<intercalate(", ", [ js2txt(p) | p <- params ])>) {
   '  <js2txt(statBody)>
   '}"; 

//str js2txt(function(str name, // "" = null 
//            list[Pattern] params, 
//            list[Expression] defaults,
//            str rest, // "" = null
//            Expression expBody,
//            bool generator)) = ""; 
//
//str js2txt(arrow(list[Pattern] params, 
//  			list[Expression] defaults,
//            str rest, // "" = null
//            Statement statBody,
//            bool generator)) = ""; 
//
//str js2txt(arrow(list[Pattern] params, 
//  			list[Expression] defaults,
//            str rest, // "" = null
//            Expression expBody,
//            bool generator)) = "";

str js2txt(sequence(list[Expression] expressions)) 
  = "(<intercalate(", ", [ js2exp(e) | e <- expressions ])>)";
  
str js2txt(unary(UnaryOperator operator, true, Expression argument)) 
  = "(<js2txt(operator)><js2txt(argument)>)";
  
str js2txt(unary(UnaryOperator operator, false, Expression argument)) 
  = "(<js2txt(argument)>)<js2txt(operator)>";
  
str js2txt(binary(BinaryOperator binaryOp, Expression left, Expression right)) 
  = "(<js2txt(left)> <js2txt(binaryOp)> <js2txt(right)>)";

str js2txt(assignment(AssignmentOperator assignOp, Expression left, Expression right)) 
  = "<js2txt(left)> <js2txt(assignOp)> <js2txt(right)>)";
  
str js2txt(update(UpdateOperator updateOp, Expression argument, true)) 
  = "(<js2txt(updateOp)><js2txt(argument)>)";

str js2txt(update(UpdateOperator updateOp, Expression argument, false)) 
  = "(<js2txt(argument)>)<js2txt(updateOp)>";


str js2txt(logical(LogicalOperator logicalOp, Expression left, Expression right)) 
  = "(<js2txt(left)> <js2txt(logicalOp)> <js2txt(right)>)";

str js2txt(conditional(Expression \test, Expression consequent, Expression alternate))
  = "(<js2txt(\test)> ? <js2txt(consequent)> : <js2txt(alternate)>)";

str js2txt(new(Expression callee, list[Expression] arguments)) 
  = "(new <js2txt(callee)>(<intercalate(", ", [ js2txt(a) | a <- arguments ])>))";
  
str js2txt(call(Expression callee, list[Expression] arguments))
  = "(<js2txt(callee)>(<intercalate(", ", [ js2txt(a) | a <- arguments, bprintln("a = <a>") ])>))";

str js2txt(member(Expression object, str strProperty)) 
  = "(<js2txt(object)>.<strProperty>)";
  
str js2txt(member(Expression object, Expression expProperty)) 
  = "(<js2txt(object)>[<js2txt(expProperty)>])";

//str js2txt(yield(Expression argument)) = "";
//str js2txt(yield()) = "";
//str js2txt(comprehension(Expression expBody, list[ComprehensionBlock] blocks, Expression \filter)) = "";
//str js2txt(comprehension(Expression expBody, list[ComprehensionBlock] blocks)) = "";
//str js2txt(generator(Expression expBody, list[ComprehensionBlock] blocks, Expression \filter)) = "";
//str js2txt(generator(Expression expBody, list[ComprehensionBlock] blocks)) = "";
//str js2txt(graph(int index, Literal expression)) = "";
//str js2txt(graphIndex(int index)) = "";
//str js2txt(let(list[tuple[Pattern id, Init init]] bindings, Expression expBody)) = "";

str js2txt(Expression::variable(str name)) = name;
str js2txt(literal(Literal lit)) = js2txt(lit);
str js2txt(undefined()) = "undefined";
  
//str js2txt(object(list[tuple[LitOrId key, Pattern \value]] properties)) = "";
//str js2txt(array(list[Pattern] elements)) = ""; // elts contain null!
str js2txt(Pattern:: variable(str name)) = name;

str js2txt(switchCase(Expression \test, list[Statement] consequent)) 
  = "case <js2txt(\test)>:
    ' <for (s <- consequent) {><js2txt(s)>
    ' <}>";
    
str js2txt(switchCase(list[Statement] consequent)) 
  = "default:
    ' <for (s <- consequent) {><js2txt(s)>
    ' <}>";

//str js2txt(catchClause(Pattern param, Expression guard, Statement statBody)) 
//    = ""; // blockstatement

str js2txt(catchClause(Pattern param, Statement statBody)) 
  = "catch (<js2txt(param)>) {
    '  <js2txt(statBody)>
    '}"; // blockstatement
  
//str js2txt(comprehensionBlock(Pattern left, Expression right, bool each)) = "";
  
str js2txt(string(str strValue)) = "\'<strValue>\'";
str js2txt(boolean(bool boolValue)) = "<boolValue>";
str js2txt(null()) = "null";
str js2txt(number(num numValue)) = "<numValue>";
//str js2txt(regExp(str regexp)) = "";


str js2txt(UnaryOperator::min()) = "-";
str js2txt(UnaryOperator::plus()) = "+";
str js2txt(UnaryOperator::not()) = "!";
str js2txt(UnaryOperator::bitNot()) = "~";
str js2txt(UnaryOperator::typeOf()) = "typeof";
str js2txt(UnaryOperator::\void()) = "void";
str js2txt(UnaryOperator::delete()) = "delete";

str js2txt(BinaryOperator::equals()) = "==";
str js2txt(BinaryOperator::notEquals()) = "!=";
str js2txt(BinaryOperator::longEquals()) = "===";
str js2txt(BinaryOperator::longNotEquals()) = "!==";
str js2txt(BinaryOperator::lt()) = "\<";
str js2txt(BinaryOperator::gt()) = "\>";
str js2txt(BinaryOperator::leq()) = "\<=";
str js2txt(BinaryOperator::geq()) = "\>=";
str js2txt(BinaryOperator::shiftLeft()) = "\<\<";
str js2txt(BinaryOperator::shiftRight()) = "\>\>";
str js2txt(BinaryOperator::longShiftRight()) = "\>\>\>";
//str js2txt(BinaryOperator::longShiftLeft()) = "\<\<\<";
str js2txt(BinaryOperator::plus()) = "+";
str js2txt(BinaryOperator::min()) = "-";
str js2txt(BinaryOperator::times()) = "*";
str js2txt(BinaryOperator::div()) = "/";
str js2txt(BinaryOperator::rem()) = "%";
str js2txt(BinaryOperator::bitOr()) = "|";
str js2txt(BinaryOperator::bitAnd()) = "&";
str js2txt(BinaryOperator::bitXor()) = "^";
str js2txt(BinaryOperator::\in()) = "in";
str js2txt(BinaryOperator::instanceOf()) = "instanceof";
str js2txt(BinaryOperator::range()) = "..";

str js2txt(LogicalOperator::or()) = "||";
str js2txt(LogicalOperator::and()) = "&&";

str js2txt(AssignmentOperator::assign()) = "=";
str js2txt(AssignmentOperator::shiftLeftAssign()) = "\<\<=";
str js2txt(AssignmentOperator::shiftRightAssign()) = "\>\>=";
str js2txt(AssignmentOperator::longShiftRightAssign()) = "\>\>\>=";
//str js2txt(AssignmentOperator::longShiftLeftAssign()) = "\<\<\<=";
str js2txt(AssignmentOperator::plusAssign()) = "+=";
str js2txt(AssignmentOperator::minAssign()) = "-=";
str js2txt(AssignmentOperator::timesAssign()) = "*=";
str js2txt(AssignmentOperator::divAssign()) = "/=";
str js2txt(AssignmentOperator::remAssign()) = "%=";
str js2txt(AssignmentOperator::bitOrAssign()) = "|=";
str js2txt(AssignmentOperator::bitAndAssign()) = "&=";
str js2txt(AssignmentOperator::bitXorAssign()) = "^=";

str js2txt(inc()) = "++";
str js2txt(dec()) = "--";

//
// data Function
//  = function(str name, // "" = null 
//            list[Pattern] params, 
//            list[Expression] defaults,
//            str rest, // "" = null
//            Statement statBody,
//            bool generator = false) 
//str js2txt(function(str name, // "" = null 
//            list[Pattern] params, 
//            list[Expression] defaults,
//            str rest, // "" = null
//            Expression expBody,
//            bool generator = false); 
 
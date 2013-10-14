module core::lang::\syntax::JS2Text

import core::lang::\syntax::JavascriptAST;
import List;
import String;
import IO;

data Program
  = program(list[Statement] stats)
  ;

str js2txt(program(ss)) = intercalate("\n", [ js2txt(s) | s <- ss ]);


//str js2txt(ForInit::varDecl(decls, kind)) 
//  = "<kind> <intercalate(", ", [ js2txt(d) | d <- decls ])>;";

// WHOA: bug, this one fires for expression in Statement...
//str js2txt(ForInit::expression(e)) = js2txt(e) + "!!!"; 
//
//str js2txt(ForInit::none()) = ""; 

//str js2txt(Init::expression(e)) = js2txt(e) + "???"; 
//str js2txt(Init::none()) = ""; 


str js2txt(empty()) = ";";

//str js2txt(block([s, *ss])) 
//  = "{
//     <for (s <- stats) {>
//    '  <js2txt(s)><}>
//    '}";

str js2txt(block(list[Statement] stats)) 
  = "{<for (s <- stats) {>
    '  <js2txt(s)><}>
    '}";
    
str js2txt(Statement::expression(Expression exp)) = "<jse2txt(exp)>;";

str js2txt(\if(Expression \test, Statement consequent, Statement alternate)) 
  = "if (<jse2txt(\test)>) { 
    '  <js2txt(consequent)> 
    '}
    'else { 
    '  <js2txt(alternate)>
    '}"
  when !(consequent is block), !(alternate is block);  

str js2txt(\if(Expression \test, Statement consequent, Statement alternate)) 
  = "if (<jse2txt(\test)>) <js2txt(consequent)> else <js2txt(alternate)>"
  when consequent is block, alternate is block;  

str js2txt(\if(Expression \test, Statement consequent, Statement alternate)) 
  = "if (<jse2txt(\test)>) <js2txt(consequent)>
    'else {
    '  <js2txt(alternate)>
    '}"
  when consequent is block, !(alternate is block);  

str js2txt(\if(Expression \test, Statement consequent, Statement alternate)) 
  = "if (<jse2txt(\test)>) { 
    '  <js2txt(consequent)> 
    '} 
    'else <js2txt(alternate)>"
  when !(consequent is block), alternate is block; 

  
str js2txt(\if(Expression \test, Statement consequent)) 
  = "if (<jse2txt(\test)>) <js2txt(consequent)>"
  when consequent is block;

str js2txt(\if(Expression \test, Statement consequent)) 
  = "if (<jse2txt(\test)>) {
    '  <js2txt(consequent)>
    '}"
  when !(consequent is block);

str js2txt(labeled(str label, Statement statBody)) = "<label>: <js2txt(statBody)>";
str js2txt(\break()) = "break;";
str js2txt(\break(label)) = "break <label>;" when label != "";

str js2txt(\continue()) = "continue;";
str js2txt(\continue(label)) = "continue <label>;";

  
str js2txt(with(Expression object, Statement statBody)) 
  = "with (<jse2txt(object)>) {<js2txt(statBody)>}";

str js2txt(\switch(Expression discriminant, list[SwitchCase] cases)) 
  = "switch (<jse2txt(discriminant)>) {<for (c <- cases) {>
    '  <js2txt(c)><}>
    '}
    ";

str js2txt(\return(Expression argument)) = "return <jse2txt(argument)>;";
str js2txt(\return()) = "return;";

str js2txt(\throw(Expression argument)) = "throw <jse2txt(argument)>";
  
str js2txt(\try(list[Statement] block, CatchClause handler, list[Statement] finalizer))
  = "try {<for (s <- block) {><js2txt(s)>
    '     <}>
    '}
    '<js2txt(handler)>
    'finally {<for (s <- finalize) {><js2txt(s)>
    '         <}>
    '}";
     
str js2txt(\try(list[Statement] block, CatchClause handler)) 
  = "try {<for (s <- block) {><js2txt(s)>
    '     <}>
    '}
    '<js2txt(handler)>";


str js2txt(\while(Expression \test, Statement statBody)) 
  = "while (<jse2txt(\test)>) <js2txt(statBody)>";
  
str js2txt(doWhile(Statement statBody, Expression \test)) 
  = "do <js2txt(statBody)> while (<jse2txt(\test)>)";

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
  		list[Statement] statBody)) 
  = "function <id>(<intercalate(", ", [ js2txt(p) | p <- params ])>) {<for (s <- statBody) {>
    '  <js2txt(s)><}>
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
  = "<id.name><init == Init::none() ? "" : " = <jse2txt(init.exp)>">";

str jse2txt(this()) = "this";
str jse2txt(Expression::array(list[Expression] elements)) 
  = "[<intercalate(", ", [ jse2txt(e) | e <- elements ])>]";

str jse2txt(Expression::object(list[tuple[LitOrId key, Expression \value, str kind]] properties)) 
  = "{
    '  <intercalate(",\n", [ "<js2txt(k)>: <jse2txt(v)>" | <k, v, _> <- properties ])>
    '}";
    
str js2txt(LitOrId::id(str name)) = name;
str js2txt(LitOrId::lit(Literal v)) = js2txt(v);
  
    
str jse2txt(Expression::function(str name, // "" = null 
            list[Pattern] params, 
            list[Expression] defaults,
            str rest, // "" = null
            list[Statement] statBody)) 
 = "function <name>(<intercalate(", ", [ js2txt(p) | p <- params ])>) {<for (s <- statBody) {>
   '  <js2txt(s)><}>
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

str jse2txt(sequence(list[Expression] expressions)) 
  = "(<intercalate(", ", [ js2exp(e) | e <- expressions ])>)";
  
str jse2txt(unary(UnaryOperator operator, true, Expression argument)) 
  = "(<js2txt(operator)><jse2txt(argument)>)";
  
str jse2txt(unary(UnaryOperator operator, false, Expression argument)) 
  = "(<jse2txt(argument)>)<js2txt(operator)>";
  
str jse2txt(binary(BinaryOperator binaryOp, Expression left, Expression right)) 
  = "(<jse2txt(left)> <js2txt(binaryOp)> <jse2txt(right)>)";

str jse2txt(assignment(AssignmentOperator assignOp, Expression left, Expression right)) 
  = "<jse2txt(left)> <js2txt(assignOp)> <jse2txt(right)>";
  
str jse2txt(update(UpdateOperator updateOp, Expression argument, true)) 
  = "(<js2txt(updateOp)><jse2txt(argument)>)";

str jse2txt(update(UpdateOperator updateOp, Expression argument, false)) 
  = "(<jse2txt(argument)>)<js2txt(updateOp)>";


str jse2txt(logical(LogicalOperator logicalOp, Expression left, Expression right)) 
  = "(<jse2txt(left)> <js2txt(logicalOp)> <jse2txt(right)>)";

str jse2txt(conditional(Expression \test, Expression consequent, Expression alternate))
  = "(<jse2txt(\test)> ? <jse2txt(consequent)> : <jse2txt(alternate)>)";

str jse2txt(new(Expression callee, list[Expression] arguments)) 
  = "(new <jse2txt(callee)>(<intercalate(", ", [ jse2txt(a) | a <- arguments ])>))";
  
str jse2txt(call(Expression callee, list[Expression] arguments))
  = "<jse2txt(callee)>(<intercalate(", ", [ jse2txt(a) | a <- arguments ])>)";

str jse2txt(member(Expression object, str strProperty)) 
  = "<jse2txt(object)>.<strProperty>";
  
str jse2txt(member(Expression object, Expression expProperty)) 
  = "<jse2txt(object)>[<jse2txt(expProperty)>]";

//str js2txt(yield(Expression argument)) = "";
//str js2txt(yield()) = "";
//str js2txt(comprehension(Expression expBody, list[ComprehensionBlock] blocks, Expression \filter)) = "";
//str js2txt(comprehension(Expression expBody, list[ComprehensionBlock] blocks)) = "";
//str js2txt(generator(Expression expBody, list[ComprehensionBlock] blocks, Expression \filter)) = "";
//str js2txt(generator(Expression expBody, list[ComprehensionBlock] blocks)) = "";
//str js2txt(graph(int index, Literal expression)) = "";
//str js2txt(graphIndex(int index)) when bprintln("test = <\test>") = "";
//str js2txt(let(list[tuple[Pattern id, Init init]] bindings, Expression expBody)) = "";

str jse2txt(Expression::variable(str name)) = name;
str jse2txt(literal(Literal lit)) = js2txt(lit);
str jse2txt(undefined()) = "undefined";
  
//str js2txt(object(list[tuple[LitOrId key, Pattern \value]] properties)) = "";
//str js2txt(array(list[Pattern] elements)) = ""; // elts contain null!
str js2txt(Pattern::variable(str name)) = name;

str js2txt(switchCase(Expression \test, list[Statement] consequent)) 
  = "case <jse2txt(\test)>:<for (s <- consequent) {>
    ' <js2txt(s)><}>";
    
str js2txt(switchCase(list[Statement] consequent)) 
  = "default:<for (s <- consequent) {>
    ' <js2txt(s)><}>";

//str js2txt(catchClause(Pattern param, Expression guard, Statement statBody)) 
//    = ""; // blockstatement

str js2txt(catchClause(Pattern param, list[Statement] statBody)) 
  = "catch (<js2txt(param)>) {
    '  <for (s <- statBody) {>
    '    <js2txt(s)><}>
    '}"; // blockstatement
  
//str js2txt(comprehensionBlock(Pattern left, Expression right, bool each)) = "";
  

str escapeIt(str x) = escape(x, ("\"": "\\\"", "\n": "\\n", "\t": "\\t"));
  
str js2txt(Literal::string(str strValue)) = "\"<escapeIt(strValue)>\"";
str js2txt(Literal::boolean(bool boolValue)) = "<boolValue>";
str js2txt(Literal::null()) = "null";
str js2txt(Literal::number(num numValue)) = "<numValue>";
//str js2txt(regExp(str regexp)) = "";


str js2txt(UnaryOperator::min()) = "-";
str js2txt(UnaryOperator::plus()) = "+";
str js2txt(UnaryOperator::not()) = "!";
str js2txt(UnaryOperator::bitNot()) = "~";
str js2txt(UnaryOperator::typeOf()) = "typeof ";
str js2txt(UnaryOperator::\void()) = "void ";
str js2txt(UnaryOperator::delete()) = "delete ";

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
 
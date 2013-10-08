module core::lang::\syntax::JavascriptAST


data Program
  = program(list[Statement] stats)
  ;


data Function
  = function(str name, // "" = null 
            list[Pattern] params, 
            list[Expression] defaults,
            str rest, // "" = null
            Statement statBody,
            bool generator = false) 
  | function(str name, // "" = null 
            list[Pattern] params, 
            list[Expression] defaults,
            str rest, // "" = null
            Expression expBody,
            bool generator = false); 

data ForInit
  = varDecl(list[VariableDeclarator] declarations, str kind)
  | expression(Expression exp)
  | none()
  ;

data Init
  = expression(Expression exp)
  | none()
  ;


data Statement
  = empty()
  | block(list[Statement] stats)
  | expression(Expression exp)
  | \if(Expression \test, Statement consequent, Statement alternate)
  | \if(Expression \test, Statement consequent)
  | labeled(str label, Statement statBody)
  | \break(str label = "")  
  | \continue(str label = "")  
  | with(Expression object, Statement statBody)
  | \switch(Expression discriminant, list[SwitchCase] cases, bool \lexical = false)
  | \return(Expression argument)
  | \return()
  | \throw(Expression argument)  
  | \try(Statement block, CatchClause handler, list[CatchClause] guardedHandlers, Statement finalizer)
  | \try(Statement block, list[CatchClause] guardedHandlers, Statement finalizer)
  | \try(Statement block, CatchClause handler, list[CatchClause] guardedHandlers)
  | \try(Statement block, list[CatchClause] guardedHandlers)
  | \while(Expression \test, Statement statBody)  
  | doWhile(Statement statBody, Expression \test)
  | \for(ForInit init, list[Expression] exps, Statement statBody) // exps contains test, update
  | forIn(list[VariableDeclarator] decls, str kind, Expression right, Statement statBody)  
  | forIn(Expression left, Expression right, Statement statBody)
  | forOf(list[VariableDeclarator] decls, str kind, Expression right, Statement statBody)  
  | forOf(Expression left, Expression right, Statement statBody)
  | let(list[tuple[Pattern id, Init init]], Statement statBody)
  | debugger()  
  | functionDecl(str id, list[Pattern] params, 
  		list[Expression] defaults,
  		str rest, // "" = null
  		Statement statBody, 
  		bool generator)
  | functionDecl(str id, list[Pattern] params, 
  		list[Expression] defaults,
  		str rest, // "" = null
  		Expression expBody, 
  		bool generator)
  | varDecl(list[VariableDeclarator] declarations, str kind)
  ;
  


data VariableDeclarator
  = variableDeclarator(Pattern id, Init init)
  ;

data LitOrId
  = id(str name)
  | lit(Literal \value)
  ;

data Expression
  = this()
  | array(list[Expression] elements)
  | object(list[tuple[LitOrId key, Expression \value, str kind]] properties)  
  | function(str name, // "" = null 
            list[Pattern] params, 
            list[Expression] defaults,
            str rest, // "" = null
            Statement statBody,
            bool generator = false) 
  | function(str name, // "" = null 
            list[Pattern] params, 
            list[Expression] defaults,
            str rest, // "" = null
            Expression expBody,
            bool generator = false) 
  | arrow(list[Pattern] params, 
  			list[Expression] defaults,
            str rest, // "" = null
            Statement statBody,
            bool generator = false) 
  | arrow(list[Pattern] params, 
  			list[Expression] defaults,
            str rest, // "" = null
            Expression expBody,
            bool generator = false)
  | sequence(list[Expression] expressions)
  | unary(UnaryOperator operator, bool prefix, Expression argument)
  | binary(BinaryOperator binaryOp, Expression left, Expression right)
  | assignment(AssignmentOperator assignOp, Expression left, Expression right)
  | update(UpdateOperator updateOp, Expression argument, bool prefix)
  | logical(LogicalOperator logicalOp, Expression left, Expression right)
  | conditional(Expression \test, Expression consequent, Expression alternate)
  | new(Expression callee, list[Expression] arguments)
  | call(Expression callee, list[Expression] arguments)
  | member(Expression object, str strProperty)
  | member(Expression object, Expression expProperty)
  | yield(Expression argument)
  | yield()
  | comprehension(Expression expBody, list[ComprehensionBlock] blocks, Expression \filter)
  | comprehension(Expression expBody, list[ComprehensionBlock] blocks)
  | generator(Expression expBody, list[ComprehensionBlock] blocks, Expression \filter)
  | generator(Expression expBody, list[ComprehensionBlock] blocks)
  | graph(int index, Literal expression)
  | graphIndex(int index)
  | let(list[tuple[Pattern id, Init init]], Expression expBody)
  // not in Spidermonkey's AST API?
  | variable(str name)
  | literal(Literal lit)
  | undefined()
  ;
  
data Pattern
  = object(list[tuple[LitOrId key, Pattern \value]] properties)
  | array(list[Pattern] elements) // elts contain null!
  | variable(str name)
  ;   

data SwitchCase
  = switchCase(Expression \test, list[Statement] consequent)
  | switchCase(list[Statement] consequent)
  ;
  
data CatchClause
  = catchClause(Pattern param, Expression guard, Statement statBody) // blockstatement
  | catchClause(Pattern param, Statement statBody) // blockstatement
  ;
  
data ComprehensionBlock
  = comprehensionBlock(Pattern left, Expression right, bool each = false);
  
data Literal
  = string(str strValue)
  | boolean(bool boolValue)
  | null()
  | number(num numValue)
  | regExp(str regexp)
  ;

data UnaryOperator
  = min() | plus() | not() | bitNot() | typeOf() | \void() | delete();
   
data BinaryOperator
  = equals() | notEquals() | longEquals() | longNotEquals()
  | lt() | leq() | gt() | geq()
  | shiftLeft() | shiftRight() | longShiftRight()
  | plus() | min() | times() | div() | rem()
  | bitOr() | bitXor() | bitAnd() | \in()
  | instanceOf() | range()
  ;

data LogicalOperator
  = or() | and()
  ;

data AssignmentOperator
  = assign() | plusAssign() | minAssign() | timesAssign() | divAssign() | remAssign()
  | shiftLeftAssign() | shiftRightAssign() | longShiftRightAssign()
  | bitOrAssign() | bitXorAssign() | bitAndAssign();

data UpdateOperator
  = inc() | dec()
  ;


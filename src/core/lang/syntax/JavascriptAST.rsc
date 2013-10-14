module core::lang::\syntax::JavascriptAST


data Program
  = program(list[Statement] stats)
  ;

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
  | labeled(str label, Statement stat)
  | \break(str label = "")  
  | \continue(str label = "")  
  | with(Expression object, Statement stat)
  | \switch(Expression discriminant, list[SwitchCase] cases)
  | \return(Expression argument)
  | \return()
  | \throw(Expression argument)  
  | \try(list[Statement] block, CatchClause handler, list[Statement] finalizer)
  | \try(list[Statement] block, CatchClause handler)
  | \try(list[Statement] block, CatchClause handler, list[CatchClause] guardedHandlers, list[Statement] finalizer)
  | \try(list[Statement] block, list[CatchClause] guardedHandlers, list[Statement] finalizer)
  | \try(list[Statement] block, CatchClause handler, list[CatchClause] guardedHandlers)
  | \try(list[Statement] block, list[CatchClause] guardedHandlers)
  | \while(Expression \test, Statement body)  
  | doWhile(Statement body, Expression \test)
  | \for(ForInit init, list[Expression] exps, Statement body) // exps contains test, update
  | forIn(list[VariableDeclarator] decls, str kind, Expression right, Statement body)  
  | forIn(Expression left, Expression right, Statement body)
  | forOf(list[VariableDeclarator] decls, str kind, Expression right, Statement body)  
  | forOf(Expression left, Expression right, Statement body)
  | let(list[tuple[Pattern id, Init init]], Statement body)
  | debugger()  
  | functionDecl(str id, list[Pattern] params, 
  		list[Expression] defaults,
  		str rest, // "" = null
  		list[Statement] statBody, 
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
            list[Statement] statBody) // ,
            //bool generator = false) 
  | function(str name, // "" = null 
            list[Pattern] params, 
            list[Expression] defaults,
            str rest, // "" = null
            Expression expBody)
            //,
            //bool generator = false) 
  | arrow(list[Pattern] params, 
  			list[Expression] defaults,
            str rest, // "" = null
            list[Statement] statBody,
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
  = catchClause(Pattern param, Expression guard, list[Statement] statBody) // blockstatement
  | catchClause(Pattern param, list[Statement] statBody) // blockstatement
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


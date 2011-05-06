=begin
  Regular (alt/sequence/repeat)
    -- allows repetition and variability
  ProtoInstance (class, field, code, ref)  *BUT NOT VALUE*
    -- used for querying a source object during render
    -- or creating Instantiation calls during parsing
  Grammar (rules and calls)
    -- use for recursive rules, 
  Instance = ProtoInstance + Value
    -- used to represent actual instantiation 
    
  TokenStream (sequence, int/string/sym literals)

  Parameterize(A) = ParameterizePrims(A) + InstancePattern
    Weaves "field access" into the structure of A. 
    Depending on what fields are used, any type B can be the source to create As
       subst :: B -> Parameterize(A) -> A
       match :: A -> Parameterize(A) -> Inst -> B
     All primitive values of A can be constants or source fields
     All complex values can be wrapped with fields and class-tests
  
  Templatize(A) = Grammar + Regular + Parameterize(TokenStream)
    Weaves "field access", and conditiona/iteration and recursive definitions into A
       render :: B -> Templatize(A) -> A
       parse :: A -> Templatize(A) -> Inst -> B
  
  ParameterizePrims(x, "T") = 
--------
     class X < T
       foo: prim
 ==> 
     class X < T
       foo: primBind
       
     class primBind
     
     class primData < primBind
       value: prim

     class primField < primData
       expression: string
------------

  TextGrammar = Templatize(TokenStream)
  ParseTree = Instance + TokenStream
  Instance = ProtoInstance + Value
  
  DiagramGrammar = Templatize(Diagram)

  validate takes an instance of Templatize(X) and a schema S an checks that
    the class/field operations match S
        if validateInstantiation(S :: Schema, T :: Templatize(X))
           then render(S, Templatize(X)) : X

=end
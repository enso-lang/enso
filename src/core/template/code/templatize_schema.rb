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
  
  templatize_schema(A) = Grammar + Regular + Parameterize(TokenStream)
    Weaves "field access", and conditiona/iteration and recursive definitions into A
       render :: B -> templatize_schema(A) -> A
       parse :: A -> templatize_schema(A) -> Inst -> B
  
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

*need multiple inheritance!!!!*
intData < intBind
intField < intBind, Field
boolData < boolBind
boolField < boolBind, Field

------------

  TextGrammar = templatize_schema(TokenStream)
  ParseTree = Instance + TokenStream
  Instance = ProtoInstance + Value
  
  DiagramGrammar = templatize_schema(Diagram)

  validate takes an instance of templatize_schema(X) and a schema S an checks that
    the class/field operations match S
        if validateInstantiation(S :: Schema, T :: templatize_schema(X))
           then render(S, templatize_schema(X)) : X

=end

require 'core/system/load/load'
require 'core/schema/tools/copy'
  
def ParameterizePrimitives(old)
  factory = Factory.new(Loader.load('schema.schema'))
  
  base_copier = Copy.new(factory)
  new = base_copier.copy(old)
  

  primBind = Loader.loadText 'schema', <<-ENDSCHEMA 
    class ParameterData end
    class ParameterValue < ParameterData
      value: atom
    end
    class ParameterExpr < ParameterData
      expression: str
    end
    primitive atom
    primitive str
  ENDSCHEMA

  identify = {}
  identify[primBind] = new
  identify[primBind.primitives["str"]] = new.primitives["str"]
  identify[primBind.primitives["atom"]] = new.primitives["atom"]
  primBind.classes.each do |x|
    copier = Copy.new(factory, identify)
    new.types << copier.copy(x)
  end
  puts "#{new.types}"
  old.classes.each do |klass|
    base_copier.copy(klass).fields.each do |field|
      if field.type.Primitive?
        name = "#{field.type.name}Bind"
        field.type = new.types["ParameterData"]
      end
    end
  end
  
  regular = Loader.load('regular.schema');
  identify = {}
  regular.primitives.each do |x|
    next if !new.primitives[x.name]
    identify[x.name] = x.name
  end 
  return merge(regular, new, identify)
end

if __FILE__ == $0 then

  require 'core/schema/tools/print'
  require 'core/grammar/code/layout'
  SG = Loader.load('schema.grammar')
  
  s = Loader.load('point.schema')
  ts = ParameterizePrimitives(s)
  DisplayFormat.print(SG, ts)
  puts "-"*50
  s = Loader.load('genealogy.schema')
  ts = ParameterizePrimitives(s)
  DisplayFormat.print(SG, ts)
end

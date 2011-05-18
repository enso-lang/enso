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
  
  Templatetize(x, "T") = 
  
for every 
--------
  primitive str
  primitive bool
  class Initialize
    code: str
  end
classes: {
 class [name] < supers:[name], 
                [(!root && supers.length == 0) ? name + "Template" : nil], 
                [supers.length == 0 ? "Initialize" : nil]
   defined_fields: {
     [name] : [case
                when type.Primitive? then "str" // TODO: Expression!
                when traversal && !type.root && type.supers.length == 0 then name + "Template"
                when traversal then name
                else name "Ref"]
        [run optional=true; many=many; traversal=traversal]
   }
 class Ref
   label: str // TODO: Expression
   name: bool
 end
 if !root && supers.length == 0 {
  class [name + "Template"] end
  // this is a the Regular language with names changed
  // include Regular(name + "Template")
  class [name + "Alt"] < [name + "Template"]
    !alts: [name + "Template"]*
  end
  class [name + "Seq"] < [name + "Template"]
    items: [name + "Template"]*
  end
  class [name + "Repeat"] < [name + "Template"]
    collection: str // TODO: Expression
    body: [name + "Template"]*
  end
  class [name + "Cond"] < [name + "Template"]
    condition: str // TODO: Expression
    body: [name + "Template"]*
  end
  class [name + "Label"] < [name + "Template"]
    label: str // TODO: Expression
    body: [name + "Template"]*
  end
 }
}
--------------

  TextGrammar = templatize_schema(TokenStream)
  ParseTree = Instance + TokenStream
  Instance = ProtoInstance + Value
  
  DiagramGrammar = templatize_schema(Diagram)

  validate takes an instance of templatize_schema(X) and a schema S an checks that
    the class/field operations match S
        if validateInstantiation(S :: Schema, T :: templatize_schema(X))
           then render(S, templatize_schema(X)) : X

=end


require 'core/system/boot/schema_gen'
require 'core/system/load/load'

class TemplatizeSchema < SchemaGenerator

  def self.templatize(root)
    primitive :str
    primitive :bool
  
    klass Initialize do
      field :code, :type => :str
    end
    
    klass Ref do
      field :label, :type => :str     # TODO: Expression
      field :name, :type => :bool
    end

    old_schema = root.schema
    @@templatized = old_schema.classes.select do |klass|
      klass.supers.empty? && klass != root
    end
    old_schema.classes.each do |klass|
      regular(klass) if @@templatized.include?(klass)
      templatize_class(klass)
    end
    patch_schema_pointers(schema)
  end
  
  def self.templatize_class(old)
    klass get_class(old.name) do
      old.supers.each do |s|
        super_class get_class(s.name)
      end
      super_class get_class(old.name + "Template") if @@templatized.include?(old)
      #super_class Initialize if old.supers.empty?
      
      old.defined_fields.each do |f|
        next if f.computed || (f.inverse && f.inverse.traversal)
        many = f.many
        optional = f.optional
        type = case
          when f.type.Primitive?
            :str # TODO: Expression!
          when f.traversal && @@templatized.include?(f.type) 
            many = optional = false
            get_class(f.type.name + "Template")
          when f.traversal
            get_class(f.type.name)
          else 
            get_class("Ref")
          end
        field f.name, :type => type, :optional => optional, :many => many, :traversal => f.traversal
      end
    end
  end

  def self.regular(old)
    base = get_class(old.name + "Template")

    klass base do
    end
    
    klass get_class(old.name + "Alt") do
      super_class base
      field :alts, :type => base, :optional => true, :many => true, :traversal => true
    end

    klass get_class(old.name + "Seq") do
      super_class base
      field :items, :type => base, :optional => true, :many => true, :traversal => true
    end

    klass get_class(old.name + "Repeat") do
      super_class base
      field :collection, :type => :str # TODO: expression!
      field :body, :type => base, :traversal => true
    end

    klass get_class(old.name + "Cond") do
      super_class base
      field :condition, :type => :str # TODO: expression!
      field :body, :type => base, :traversal => true
    end

    klass get_class(old.name + "Label") do
      super_class base
      field :label, :type => :str # TODO: expression!
      field :body, :type => base, :traversal => true
    end
  end
end

if __FILE__ == $0 then

  require 'core/system/load/load'
  require 'core/schema/tools/print'
  require 'core/grammar/code/layout'

  
  sg = Loader.load("schema.grammar")
  puts "-"*50
  class TemplatizeSchemaSchema < TemplatizeSchema
    templatize(Loader.load("schema.schema").classes["Schema"])
  end
  Print.print(TemplatizeSchemaSchema.schema)
  DisplayFormat.print(sg, TemplatizeSchemaSchema.schema)

  puts "-"*50
  class TemplatizeGrammarSchema < TemplatizeSchema
    templatize(Loader.load("grammar.schema").classes["Grammar"])
  end
  DisplayFormat.print(sg, TemplatizeGrammarSchema.schema)
end
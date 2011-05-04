require 'schema/factory'
require 'schema/schemaschema'

class Changeify
  def initialize()
    @memo = {}
    @memoChange = {}
    @factory = Factory.new(SchemaSchema.schema)
     # commands = "insert", "delete", "modify", "clear"    
  end
  
  def Schema(old)
    @schema = @factory.Schema(old.name + "Changes")
    old.types.each do |t| Type(t) end
    @schema.finalize
    return @schema
  end  
  
  def Type(old)    
    new = @memo[old]
    return new if new
    new = self.send(old.schema_class.name, old)
    @schema.types << new
    return new
  end
  
  def Primitive(old)
    @memo[old] = @factory.Primitive(old.name)
  end
  
  def Klass(old)
    new = @factory.Klass(old.name)
    @memo[old] = new
    new.super = Type(old.super) if old.super # MUST USE Type to do memoization!!!
    old.defined_fields.each do |field|
      new.defined_fields << Field(field)
    end
    return new
  end
  
  def Field(old)
    new = @factory.Field(old.name)
    new.optional = true
    # no keys!
    new.many = old.many
    new.type = MakeChangeType(old.type)
    # what about inverses?
    return new
  end
  
  def MakeChangeType(old)
    new = @memoChange[old]
    return new if new
    if old.Primitive?
      @memoChange[old] = new = @factory.Klass(old.name + "Change")  
      @schema.types << new
      field = @factory.Field("value")
      field.type = Type(old)
      field.optional = true
      new.defined_fields << field
    else
      new = Type(old)  
      if new.super.nil? && new.defined_fields["change_kind"].nil?
        field = @factory.Field("change_kind")
        field.type = Type(old.schema.types["str"])
        new.defined_fields << field
      end
    end
    return new
  end
end



if __FILE__ == $0 then

  require 'grammar/cpsparser'
  require 'grammar/grammargrammar'
  require 'tools/print'
  require 'grammar/layout'
  
  sg = CPSParser.load('schema/schema.grammar', GrammarGrammar.grammar, GrammarSchema.schema)

  cons = CPSParser.load_raw('schema/schema.schema', sg, SchemaSchema.schema)
  
  deltaCons = Changeify.new.Schema(cons)

  DisplayFormat.print(sg, deltaCons)
end

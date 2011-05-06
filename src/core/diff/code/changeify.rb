require 'core/schema/code/factory'

=begin

  class Foo
    key: str (key)
    foo: int
    bar: Foo
    items: Foo*

==>

  class Foo_Change
    key: str (Key)
  
  class Foo_Delete < Foo_Change  # used for deleting in list, or clearing single-valued
  class Foo_Insert < Foo_Change  # used for inserting in list, or setting single-valued
    foo: int
    bar: Foo
    items: Foo*
  class Foo_Modify < Foo_Change # used for change in list, or changing single-valued
    foo: intChange
    bar: Foo?
    items: Foo*
  

=end


class DeltaTransform_internal
  def initialize()
    @memo = {}
    @memoChange = {}
    @factory = Factory.new(SchemaSchema.schema)
     # commands = "insert", "delete", "modify", "clear"    
  end
  
  def Schema(old)
    @schema = @factory.Schema()
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

def Delta(schema)
  return DeltaTransform_internal.new.Schema(schema)
end


if __FILE__ == $0 then

  require 'core/system/load/load'
  require 'core/schema/tools/print'
  require 'core/grammar/code/layout'
  
  cons = Loader.load('schema.schema')
  
  deltaCons = Delta(cons)

  DisplayFormat.print(Loader.load('schema.grammar'), deltaCons)
end

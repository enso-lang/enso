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

class DeltaTransform

  # name of system attribute added to record change status   
  @deltaname = "delta"
  @deltatype = "int"  #must be a primitive that appears in schema-schema
  # types of changes
  @unknown   = 0
  @added     = 1
  @deleted   = 2
  @updated   = 3
  @unchanged = 4

  def initialize()
    @alltypes = {}
#    deltaM3() we cheat by loading deltaschema from a static file
    @deltaschema = Loader.load('deltaschema.schema')
    @factory = Factory.new(@deltaschema)
  end

  def deltaM3()
    #create a delta version of the schema-schema
    # and store it locally as @deltaschema
    # note that deltaschema conforms to schema-schema
    # and all schemas of results of diff conforms to deltaschema

    #FIXME: Currently we CHEAT and load a modified copy of schema-schema statically!
    #  This will immediately fail once schema-schema is modified!!!!

    #go through all types in schema-schema
    #TODO: Make this work!
    SchemaSchema.schema.types.each do |t|
      if not t.Primitive? and t.super.nil? 
        
      end
    end
    
  end

  def delta(old)
    #given a schema conforming to schema-schema
    #convert to an equivalent schema conforming to deltaschema
    
    initialize()

    return Schema(old)
  end

  def Type(old, action)
    # this function simulated dynamic dispatch (?)
    #dynamic dispatch is needed because of subtyping

    # there is no need to do any memoization because our fixed schema-schema  
    #does not have cyclically defined inner types (no sane language does)
    # TODO: current algo very sensitive to changes to schema-schema! try to improve...

    puts old.schema_class.name
    new = self.send(action+old.schema_class.name, old)

    return new
  end
  
  def Schema(old)
    schema = @factory.Schema()
    
    # make all types first so that later fields can point to them
    old.types.each do |t|
      puts t.name
      schema.types << @alltypes[t.name] = Type(t, "make")
    end
    
    # fill out the types made earlier
    old.types.each do |t|
      puts t.name
      Type(t, "do")
    end

    # finalize the schema + do some checking
    schema.finalize
    return schema
  end  

  def makePrimitive(old)
    new = @factory.Primitive(old.name)
    new.delta = @unknown

    return new
  end
  def doPrimitive(old)
  end

  def makeKlass(old)
    return @factory.Klass(old.name)
  end
  def doKlass(old)
    new = @alltypes[old.name]

    new.delta = @unknown

    old.defined_fields.each do |t|
      new.defined_fields << Field(t)
    end

    return new
  end
  
  def Field(old)
    new = @factory.Field(old.name)
    puts "asdf"
    puts old.name
    puts old.type.name()
    new.type = @alltypes[old.type.name()]
    new.optional = old.optional
    new.many = old.many
    new.key = old.key
    new.computed = old.computed
    new.delta = @unknown
    new.traversal = old.traversal

    return new
  end

=begin  
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
=end


end

def Delta(schema)
  return DeltaTransform_internal.new.Schema(schema)
end


if __FILE__ == $0 then

  require 'core/system/load/load'
  require 'core/schema/tools/print'
  require 'core/grammar/code/layout'
  
  cons = Loader.load('points.schema')
  
  deltaCons = Delta(cons)

  DisplayFormat.print(Loader.load('deltaschema.grammar'), deltaCons)
end


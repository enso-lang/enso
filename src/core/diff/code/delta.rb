require 'core/schema/code/factory'

class DeltaTransform

  attr_reader :insert, :delete, :modify, :clear, :many, :base
  
  def initialize()
    #change operation names
    @insert = "Insert"
    @delete = "Delete"
    @modify = "Modify"
    @clear = "Clear"
    @many = "Many"
    @base = "Base"

    @factory = Factory.new(Loader.load('schema.schema'))
    @schema = @factory.Schema()
    
    #init memo for schema types
    @memo = {}
    @memo[@base] = {}
    @memo[@insert] = {}
    @memo[@delete] = {}
    @memo[@modify] = {}
    @memo[@clear] = {}
    @memo[@many+@insert] = {}
    @memo[@many+@delete] = {}
    @memo[@many+@modify] = {}

  end

  def delta(old)
    #given a schema conforming to schema-schema
    #convert to an equivalent schema conforming to deltaschema

    return Schema(old)
  end

  def Type(old, action)
    # this function simulated dynamic dispatch (?)
    #dynamic dispatch is needed because of subtyping

    # there is no need to do any memoization because our fixed schema-schema  
    #does not have cyclically defined inner types (no sane language does)

    new = self.send(action+old.schema_class.name, old)

    return new
  end
  
  def Schema(old)

    #make the basic primitives for the change record
    @int_type = @factory.Primitive("int")
    @schema.types << @int_type

    # make all types first so that later fields can point to them
    old.types.each do |t|
      makeType(t)
    end

    # fill out the types made earlier
    old.types.each do |t|
      doType(t)
    end

    # finalize the schema + do some checking
    @schema.finalize
    return @schema
  end

  def makeType(old)
    #for each type in original schema, make:
    # - base class as supertype
    # - insert, delete, modify and clear subtypes of base class
    # - many variants of insert and delete

    x = @factory.Klass(@base+old.name)
    @memo[@base][old.name] = x
    @schema.types << x

    #ins/del/mod/clr
    x = @factory.Klass(@insert+old.name)
    x.supers << @memo[@base][old.name]
    @memo[@insert][old.name] = x
    @schema.types << x

    x = @factory.Klass(@delete+old.name)
    x.supers << @memo[@base][old.name]
    @memo[@delete][old.name] = x
    @schema.types << x

    x = @factory.Klass(@modify+old.name)
    x.supers << @memo[@base][old.name]
    @memo[@modify][old.name] = x
    @schema.types << x
    
    x = @factory.Klass(@clear+old.name)
    x.supers << @memo[@base][old.name]
    @memo[@clear][old.name] = x
    @schema.types << x

    #many

    x = @factory.Klass(@many+@insert+old.name)
    x.supers << @memo[@base][old.name]
    f = @factory.Field("pos")
    f.type = @int_type
    x.fields << f
    @memo[@many+@insert][old.name] = x
    @schema.types << x

    x = @factory.Klass(@many+@delete+old.name)
    x.supers << @memo[@base][old.name]
    f = @factory.Field("pos")
    f.type = @int_type
    x.fields << f
    @memo[@many+@delete][old.name] = x
    @schema.types << x
    
    x = @factory.Klass(@many+@modify+old.name)
    x.supers << @memo[@base][old.name]
    f = @factory.Field("pos")
    f.type = @int_type
    x.fields << f
    @memo[@many+@modify][old.name] = x
    @schema.types << x

  end

  def doType(old)
    
    if old.Primitive?
      return
    end
    
    # retrieve memoized type
    x = @memo[@base][old.name]

    # establish supertype based on old supertype
    old.supers.each do |s|
      x.supers << @memo[@base][s.name]
    end

    #recreate all field from old using new classes     
    old.defined_fields.each do |t|
      x.defined_fields << Field(t)
    end
  end
  
  def Field(old)
    new = @factory.Field(old.name)
    new.type = @memo[@base][old.type.name]
    new.optional = true
    new.many = old.many
    new.key = old.key
    new.computed = old.computed
    new.traversal = new.traversal
    return new
  end

end

def Delta(schema)
  return DeltaTransform.new.Schema(schema)
end


if __FILE__ == $0 then

  require 'core/system/load/load'
  require 'core/schema/tools/print'
  require 'core/grammar/code/layout'
  
  cons = Loader.load('points.schema')
  
  deltaCons = Delta(cons)

  DisplayFormat.print(Loader.load('deltaschema.grammar'), deltaCons)
end


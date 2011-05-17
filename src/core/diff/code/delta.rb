require 'core/schema/code/factory'

class DeltaTransform

  attr_reader :insert, :delete, :modify, :clear, :many, :base
  def self.insert; "Insert_"; end
  def self.delete; "Delete_"; end
  def self.modify; "Modify_"; end
  def self.clear; "Clear_"; end
  def self.many; "Many"; end
  def self.base; "D_"; end
    
  def initialize()
    #change operation names

    @factory = Factory.new(Loader.load('schema.schema'))
    @schema = @factory.Schema()
    
    #init memo for schema types
    @memo = {}
    
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

    base = @factory.Klass(DeltaTransform.base + old.name, @schema)
    @memo[old.name] = base
    @schema.types << base

    #ins/del/mod/clr
    # NOTE: simply setting the schema pointer does not add the class to the schema!!
    @schema.types << @factory.Klass(DeltaTransform.insert + old.name, @schema, [base])
    @schema.types << @factory.Klass(DeltaTransform.delete + old.name, @schema, [base])
    @schema.types << @factory.Klass(DeltaTransform.modify + old.name, @schema, [base])
    @schema.types << @factory.Klass(DeltaTransform.clear + old.name, @schema, [base])
    
    #many

    x = @factory.Klass(DeltaTransform.many + DeltaTransform.insert + old.name, @schema, [base])
    x.defined_fields << @factory.Field("pos", x, @int_type)
    @schema.types << x

    x = @factory.Klass(DeltaTransform.many + DeltaTransform.delete + old.name, @schema, [base])
    x.defined_fields << @factory.Field("pos", x, @int_type)
    @schema.types << x
    
    x = @factory.Klass(DeltaTransform.many + DeltaTransform.modify + old.name, @schema, [base])
    x.defined_fields << @factory.Field("pos", x, @int_type)
    @schema.types << x

  end

  def doType(old)
    
    if old.Primitive?
      return
    end
    
    # retrieve memoized type
    x = @memo[old.name]

    # establish supertype based on old supertype
    old.supers.each do |s|
      x.supers << @memo[s.name]
    end

    #recreate all field from old using new classes     
    old.defined_fields.each do |t|
      x.defined_fields << Field(t)
    end
  end
  
  def Field(old)
    new = @factory.Field(old.name)
    new.type = @memo[old.type.name]
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
  
  cons = Loader.load('point.schema')
  
  deltaCons = Delta(cons)

  DisplayFormat.print(Loader.load('schema.grammar'), deltaCons)
end


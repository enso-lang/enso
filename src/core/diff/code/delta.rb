require 'core/schema/code/factory'

class DeltaTransform

  attr_reader :insert, :delete, :modify, :clear, :many, :base
  def self.insert; "Insert_"; end
  def self.delete; "Delete_"; end
  def self.modify; "Modify_"; end
  def self.clear; "Clear_"; end  #currently unused --- all objs in diff tree must have been modified
  def self.many; "Many"; end
  def self.base; "D_"; end

  def delta(old)
    #given a schema conforming to schema-schema
    #convert to an equivalent schema conforming to deltaschema

    return Schema(old)
  end
  
  def DeltaTransform.isManyChange?(obj)
    class_name = obj.schema_class.name
    #search for "_"
    index = class_name.index("_")
    change = class_name[0..index-1]
    return change.start_with?(many)
  end

  def DeltaTransform.getChangeType(obj)
    class_name = obj.schema_class.name
    #search for "_"
    index = class_name.index("_")
    change = class_name[0..index]
    if change.start_with?(many)
      change = change[many.length..change.length-1]
    end
    return change
  end

  def DeltaTransform.getObjectName(obj)
    class_name = obj.schema_class.name
    #search for "_"
    index = class_name.index("_")
    return class_name[index+1..class_name.length-1]
  end

  def DeltaTransform.isInsertChange?(obj)
    return getChangeType(obj) == insert
  end
  
  def DeltaTransform.isDeleteChange?(obj)
    return getChangeType(obj) == delete
  end

  def DeltaTransform.isModifyChange?(obj)
    return getChangeType(obj) == modify
  end

  def DeltaTransform.isClearChange?(obj)
    return getChangeType(obj) == clear
  end

  
    
  #############################################################################
  #start of private section  
  private
  #############################################################################
        
  def initialize()
    #change operation names

    @factory = Factory.new(Loader.load('schema.schema'))
    @schema = @factory.Schema()
    
    #init memo for schema types
    @memo = {}
  end

  #given a schema conforming to schema-schema
  #convert to an equivalent schema conforming to deltaschema
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
    
    return if old.Primitive?
    
    # retrieve memoized type
    x = @memo[old.name]

    # establish supertype based on old supertype
    old.supers.each do |s|
      x.supers << @memo[s.name]
    end

    #recreate all field from old using new classes     
    old.defined_fields.each do |field|
      next if field.computed
      x.defined_fields << Field(field)
    end
  end
  
  def Field(old)
    new = @factory.Field(old.name)
    new.type = @memo[old.type.name]
    new.optional = true
    new.many = old.many
    new.traversal = true
    return new
  end
end

def Delta(schema)
  return DeltaTransform.new.delta(schema)
end


if __FILE__ == $0 then

  require 'core/system/load/load'
  require 'core/schema/tools/print'
  require 'core/grammar/code/layout'
  
  deltaCons = Delta(Loader.load('point.schema'))
  DisplayFormat.print(Loader.load('schema.grammar'), deltaCons)
  puts "-"*50
  deltaCons = Delta(Loader.load('schema.schema'))
  DisplayFormat.print(Loader.load('schema.grammar'), deltaCons)
end


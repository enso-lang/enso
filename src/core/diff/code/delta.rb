require 'core/schema/code/factory'
require 'core/system/library/schema'

class DeltaTransform

  attr_reader :insert, :delete, :modify, :clear, :many, :base
  def self.insert; "Insert_"; end
  def self.delete; "Delete_"; end
  def self.modify; "Modify_"; end
  def self.clear; "Clear_"; end  #currently unused --- all objs in diff tree must have been modified
  def self.many; "Many"; end
  def self.keyed; "Keyed"; end
  def self.ref; "DeltaRef"; end
  def self.base; "D_"; end

  def delta(old)
    #given a schema conforming to schema-schema
    #convert to an equivalent schema conforming to deltaschema

    return Schema(old)
  end
 
  #TODO: currently DeltaSchema uses magic fields pos and val to store change record information,
  #      which will fail with types which already have fields named pos or val
  #      we either need a more obscure magic name (eg. "__POSITION__") or a better mechanism
  def DeltaTransform.isPrimitive?(obj)
    not obj.schema_class.all_fields["val"].nil?
  end

  def DeltaTransform.isManyChange?(obj)
    not ((obj.schema_class.supers.detect {|s| s.name == keyed or s.name == many}).nil?)
  end

  def DeltaTransform.isKeyedMany?(obj)
    not (obj.schema_class.supers.detect {|s| s.name == keyed}).nil?
  end

  def DeltaTransform.isRef?(obj)
    not (obj.schema_class.supers.detect {|s| s.name == ref}).nil?
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

  def DeltaTransform.getObjectBase(obj)
    obj.schema_class.supers.detect {|s| s.name.start_with? base }
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

  def DeltaTransform.getPos(obj)
    if ! isManyChange?(obj)
      raise "Delta: Trying to get the position of a non-Many change type"
    end
    return obj.pos
  end
  
  def DeltaTransform.getValue(obj)
    if ! isPrimitive?(obj)
      raise "Delta: Trying to get the value from a non-Primitive type"
    end
    return obj.val
  end

  # Turn an ordinary delta into a many delta
  def DeltaTransform.manyify(obj, factory, pos, reftype = "")
    #if obj already many do nothing
    return obj if DeltaTransform.isManyChange?(obj)

    #make a clone of obj of many type
    res = factory[many + obj.schema_class.name + reftype]
    schema_class = obj.schema_class

    schema_class.fields.each do |f| #copy field info
      next if obj[f.name].nil?
      if not f.many
        res[f.name] = obj[f.name]
      else
        res[f.name].clear
        obj[f.name].each do |d|
          res[f.name] << d
        end
      end
    end
    res.pos = pos #set position value
    return res
  end

  #############################################################################
  #start of private section  
  private
  #############################################################################

  def initialize()
    #change operation names

    @factory = Factory.new(Loader.load('schema.schema'))
    @schema = @factory.Schema()
    
    #init memo for base classes and primitive types
    @memo = {}
    @prims = {}
    @refs = {}

    #init default base types: many and keyed many
    @manybase = @factory.Klass(DeltaTransform.many, @schema)
    @schema.types << @manybase
    @keyedbase = @factory.Klass(DeltaTransform.keyed, @schema)
    @schema.types << @keyedbase
    #note that keyedbase does not contain pos because the type of the key
    #varies depending on object type

    #init default single-valued ref types
    @refbase = @factory.Klass(DeltaTransform.ref, @schema)
    @refbase.defined_fields << @factory.Field("path", @refbase, getPrimitiveType("str"))
    @schema.types << @refbase
    #ins/del/mod/clr
    @schema.types << @factory.Klass(DeltaTransform.insert + DeltaTransform.ref, @schema, [@refbase])
    @schema.types << @factory.Klass(DeltaTransform.delete + DeltaTransform.ref, @schema, [@refbase])
    @schema.types << @factory.Klass(DeltaTransform.modify + DeltaTransform.ref, @schema, [@refbase])
    @schema.types << @factory.Klass(DeltaTransform.clear + DeltaTransform.ref, @schema, [@refbase])
  end

  def Type(old, action)
    # this function simulated dynamic dispatch (?)
    #dynamic dispatch is needed because of subtyping

    # there is no need to do any memoization because our fixed schema-schema  
    #does not have cyclically defined inner types (no sane language does)

    new = self.send(action+old.schema_class.name, old)

    return new
  end
  
  def getPrimitiveType(name)
    return @prims[name] if @prims.has_key?(name)

    x = @factory.Primitive(name, @schema)
    @prims[name] = x 
    @schema.types << x

    r = @factory.Primitive(name, )

    return x
  end

  def getManyRefBase(keytype = "")

    if keytype == ""
      keytype = "int"
      keyed = false
    else 
      keyed = true
    end

    return @refs[keytype] if @refs.has_key?(keytype)

    base = @factory.Klass(DeltaTransform.many + DeltaTransform.ref + keytype, @schema, [@refbase, keyed ? @keyedbase : @manybase])
    base.defined_fields << @factory.Field("pos", base, getPrimitiveType(keytype))
    @refs[keytype] = base
    @schema.types << base

    @schema.types << @factory.Klass(DeltaTransform.many + DeltaTransform.insert + DeltaTransform.ref + keytype, @schema, [base])
    @schema.types << @factory.Klass(DeltaTransform.many + DeltaTransform.delete + DeltaTransform.ref + keytype, @schema, [base])
    @schema.types << @factory.Klass(DeltaTransform.many + DeltaTransform.modify + DeltaTransform.ref + keytype, @schema, [base])
    @schema.types << @factory.Klass(DeltaTransform.many + DeltaTransform.clear + DeltaTransform.ref + keytype, @schema, [base])

    return base
  end

  #given a schema conforming to schema-schema
  #convert to an equivalent schema conforming to deltaschema
  def Schema(old)

    # make all types first so that later fields can point to them
    old.types.each do |t|
      makeType(t)
    end

    # fill out the types made earlier
    old.types.each do |t|
      doType(t)
    end
    
    # finalize the schema + do some checking
    return @schema.finalize
  end

  def makeType(old)
    #for each type in original schema, make:
    # - base class as supertype
    # - insert, delete, modify and clear subtypes of base class
    # - many variants of insert and delete

    base = @factory.Klass(DeltaTransform.base + old.name, @schema)
    @memo[old.name] = base
    @schema.types << base

    #primitive to store value in base
    if old.Primitive?
      base.defined_fields << @factory.Field("val", base, getPrimitiveType(old.name))
    end

    #ins/del/mod/clr
    # NOTE: simply setting the schema pointer does not add the class to the schema!!
    @schema.types << @factory.Klass(DeltaTransform.insert + old.name, @schema, [base])
    @schema.types << @factory.Klass(DeltaTransform.delete + old.name, @schema, [base])
    @schema.types << @factory.Klass(DeltaTransform.modify + old.name, @schema, [base])
    @schema.types << @factory.Klass(DeltaTransform.clear + old.name, @schema, [base])

    #many
    keyed = IsKeyed?(old)
    poskey = keyed ? getPrimitiveType(ClassKey(old).type.name) : getPrimitiveType("int")
    m = @factory.Klass(DeltaTransform.many + DeltaTransform.insert + old.name, @schema, [base, keyed ? @keyedbase : @manybase])
    m.defined_fields << @factory.Field("pos", m, poskey)
    @schema.types << m
    m = @factory.Klass(DeltaTransform.many + DeltaTransform.delete + old.name, @schema, [base, keyed ? @keyedbase : @manybase])
    m.defined_fields << @factory.Field("pos", m, poskey)
    @schema.types << m
    m = @factory.Klass(DeltaTransform.many + DeltaTransform.modify + old.name, @schema, [base, keyed ? @keyedbase : @manybase])
    m.defined_fields << @factory.Field("pos", m, poskey)
    @schema.types << m
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
    if !old.traversal and !old.type.Primitive? #is a ref
      if not old.many
        new.type = @refbase
      else
        if IsKeyed?(old.type)
          new.type = getManyRefBase(ClassKey(old.type).type.name)
        else
          new.type = getManyRefBase()
        end
      end
    else
      new.type = @memo[old.type.name]
    end
    new.optional = true
    new.many = old.many
    new.traversal = true
    return new
  end
end

def Delta(schema)
  return DeltaTransform.new.delta(schema)
end


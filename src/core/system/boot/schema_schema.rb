

require 'core/system/boot/schema_gen'

class SchemaSchema < SchemaGenerator

  primitive :str
  primitive :int
  primitive :bool
  primitive :real

  klass Schema do
    field :types, :type => Type, :optional => true, :many => true
    field :classes, :type => Klass, :optional => true, :many => true, \
      :computed => "@types.select(&:Klass?)"
    field :primitives, :type => Primitive, :optional => true, :many => true, \
      :computed => "@types.select(&:Primitive?)"
  end
    
  klass Type do
    field :name, :type => :str, :key => true
    field :schema, :type => Schema, :inverse => Schema.types, :key => true
  end

  klass Primitive, :super => Type do
  end

  klass Klass, :super => Type do
    field :supers, :type => Klass, :optional => true, :many => true
    field :subtypes, :type => Klass, :optional => true, :many => true, :inverse => Klass.supers
    field :defined_fields, :type => Field, :optional => true, :many => true
    field :fields, :type => Field, :optional => true, :many => true, \
      :computed => "@all_fields.select {|f| !f.computed}"
    field :all_fields, :type => Field, :optional => true, :many => true, \
      :computed => "@supers.flat_map(&:all_fields) + @defined_fields"
  end

  klass Field do
    field :name, :type => :str, :key => true
    field :owner, :type => Klass, :inverse => Klass.defined_fields, :key => true
    field :type, :type => Type
    field :optional, :type => :bool
    field :many, :type => :bool
    field :key, :type => :bool
    field :inverse, :type => Field, :optional => true, :inverse => Field.inverse
    field :computed, :type => :str, :optional => true
  end

  SchemaSchema.patch_schema_pointers(schema)

end

# make a copy so it uses checked objects (but its not quite right, because
# we don't update the schema pointers!

#require 'tools/copy'
#require 'schema/factory'

#SchemaSchema.schema = Copy.new(Factory.new(SchemaSchema.schema)).copy(SchemaSchema.schema)


def main
  require 'core/schema/tools/print'
  
  Print.new.recurse(SchemaSchema.schema)
end

if __FILE__ == $0 then
  main
end

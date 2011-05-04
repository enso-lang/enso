

require 'schema/schemagen'

class SchemaSchema < SchemaGenerator

  primitive :str
  primitive :int
  primitive :bool
  primitive :real

  # this is a little model that describes how to print out schema schemas
  # perhaps it should be in the model itself
  def self.print_paths
    { :classes => { :fields => {} } }
  end

  klass Schema do
    field :name, :type => :str, :key => true
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
    field :super, :type => Klass, :optional => true
    field :subtypes, :type => Klass, :optional => true, :many => true, :inverse => Klass.super
    field :defined_fields, :type => Field, :optional => true, :many => true
    field :fields, :type => Field, :optional => true, :many => true, \
      :computed => "@super ? @super.fields + @defined_fields : @defined_fields"
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

  SchemaSchema.finalize(schema)

  def self.key(klass)
    klass.fields.find { |f| f.key && f.type.Primitive? }
  end

  def self.keyRel(klass)
    klass.fields.find { |f| f.key && !f.type.Primitive? }
  end

end

# make a copy so it uses checked objects (but its not quite right, because
# we don't update the schema pointers!

#require 'tools/copy'
#require 'schema/factory'

#SchemaSchema.schema = Copy.new(Factory.new(SchemaSchema.schema)).copy(SchemaSchema.schema)


def main
  require 'tools/print'
  
  Print.new.recurse(SchemaSchema.schema, SchemaSchema.print_paths)
end

if __FILE__ == $0 then
  main
end

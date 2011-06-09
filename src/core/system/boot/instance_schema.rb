
require 'core/system/boot/schema_schema'

class InstanceSchema < SchemaGenerator

  primitive :str
  primitive :int

  klass Instances do
    field :instances, :type => Instance, :optional => true, :many => true, :traversal => true
  end

  klass Location do
    field :path, :type => :str
    field :offset, :type => :int
    field :length, :type => :int
    field :start_line, :type => :int
    field :start_column, :type => :int
    field :end_line, :type => :int
    field :end_column, :type => :int
  end

  klass Value do
    field :origin, :type => Location, :optional => true, :traversal => true
  end

  klass Instance, :super => Value  do
    field :type, :type => :str
    field :contents, :type => Content, :optional => true, :many => true, :traversal => true
  end

  klass Prim, :super => Value do
    field :kind, :type => :str
    field :value, :type => :str, :optional => true
  end

  klass Ref, :super => Value do
    field :name, :type => :str
  end

  klass Content do
  end

  klass Field, :super => Content do
    field :name, :type => :str
    field :values, :type => Value, :optional => true, :many => true, :traversal => true
  end

  klass Code, :super => Content do
    field :code, :type => :str
  end
      

  patch_schema_pointers(schema)

end

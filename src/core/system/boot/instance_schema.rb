
require 'core/system/boot/schema_schema'

class InstanceSchema < SchemaGenerator

  primitive :str
  primitive :int
  primitive :atom

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
    field :type, :type => :str
  end

  klass Ref2, :super => Value do
    field :path, :type => Path, :traversal => true
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
      
  klass Key do
  end

  klass Const, :super => Key do
    field :value, :type => :atom
  end

  klass Path, :super => Key do
  end

  klass Anchor, :super => Path do
    field :type, :type => :str
  end

  klass Sub, :super => Path do
    field :parent, :type => Path, :traversal => true, :optional => true
    field :name, :type => :str
    field :key, :type => Key, :traversal => true, :optional => true
  end



  patch_schema_pointers(schema)

end

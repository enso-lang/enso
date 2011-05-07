
require 'core/system/boot/schema_gen'
require 'core/system/boot/schema_schema'

class ParseTreeSchema < SchemaGenerator
  primitive :str
  primitive :int
  primitive :bool

  klass ParseTree do
    field :path, :type => :str
    field :top, :type => Tree
    field :layout, :type => :str
  end

  klass Tree do
  end

  klass Sequence, :super => Tree do
    field :elements, :type => Tree, :optional => true, :many => true
  end

  klass Create, :super => Tree do
    field :name, :type => :str
    field :arg, :type => Tree
  end

  klass Code, :super => Tree do
    field :code, :type => :str
  end

  klass Field, :super => Tree do
    field :name, :type => :str
    field :arg, :type => Tree
  end

  klass Value, :super => Tree do
    field :kind, :type => :str
    field :value, :type => :str
    field :layout, :type => :str
  end

  klass Lit, :super => Tree do
    field :value, :type => :str
    field :layout, :type => :str
  end

  klass Ref, :super => Tree do
    field :name, :type => :str
    field :layout, :type => :str
  end

  SchemaSchema.patch_schema_pointers(schema)
end

if __FILE__ == $0 then
  require 'core/grammar/code/layout'
  require 'core/system/load/load'

  schema_grammar = Loader.load('schema.grammar')

  DisplayFormat.print(schema_grammar, ParseTreeSchema.schema)
end

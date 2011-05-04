
require 'schema/schemagen'
require 'schema/schemaschema'

class LayoutSchema < SchemaGenerator
  primitive :str
  primitive :int
  primitive :bool

  def self.print_paths
    {}
  end
  
  klass Format do
  end

  # Horiz
  klass Sequence, :super => Format do
    field :elements, :type => Format, :optional => true, :many => true
  end

  # HOV - hoizontal or vertical
  klass Group, :super => Format do
    field :arg, :type => Format
  end

  klass Nest, :super => Format do
    field :arg, :type => Format
    field :indent, :type => :int
  end

  klass Break, :super => Format do
    field :indent, :type => :int
    field :sep, :type => :str
  end

  klass Text, :super => Format do
    field :value, :type => :str
  end

  finalize(schema)
end

if __FILE__ == $0 then

  require 'grammar/layout'
  require 'grammar/grammargrammar'
  require 'grammar/cpsparser'

  GG = GrammarGrammar.grammar
  schema_grammar = CPSParser.load('schema/schema.grammar', GG, GrammarSchema.schema)

  DisplayFormat.print(schema_grammar, LayoutSchema.schema)
end

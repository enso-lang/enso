
require 'schema/schemagen'
require 'schema/schemaschema'

class ParseTreeSchema < SchemaGenerator
  primitive :str
  primitive :int
  primitive :bool

  def self.print_paths
    { :top => { :args => { } } }
  end
  
  klass ParseTree do
    field :path, :type => :str
    field :top, :type => Tree
    field :layout, :type => :str
  end

  klass Tree do
  end

  klass Appl, :super => Tree do
    field :rule, :type => :str
    field :arg, :type => Tree
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
    #field :case_sensitive, :type => :bool
    field :layout, :type => :str
  end

  klass Ref, :super => Tree do
    field :name, :type => :str
    field :layout, :type => :str
  end

#  klass Key, :super => Tree do
#    field :name, :type => :str
#    field :layout, :type => :str
#  end

#   klass Regular, :super => Tree do
#     field :args, :type => Tree, :optional => true, :many => true
#     field :many, :type => :bool
#     field :optional, :type => :bool
#     field :sep, :type => :str, :optional => true
#   end

  SchemaSchema.finalize(schema)
end

if __FILE__ == $0 then
  require 'grammar/layout'
  require 'grammar/grammargrammar'
  require 'grammar/cpsparser'

  GG = GrammarGrammar.grammar
  schema_grammar = CPSParser.load('schema/schema.grammar', GG, GrammarSchema.schema)

  DisplayFormat.print(schema_grammar, ParseTreeSchema.schema)
end

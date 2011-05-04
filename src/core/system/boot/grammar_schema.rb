
require 'schema/schemagen'
require 'schema/schemaschema'

class GrammarSchema < SchemaGenerator
  primitive :str
  primitive :int
  primitive :bool

  def self.print_paths
    { :rules => {} }
  end
  
  klass Grammar do
    field :name, :type => :str
    field :start, :type => Rule
    field :rules, :type => Rule, :optional => true, :many => true
  end

  klass Rule do
    field :name, :type => :str, :key => true
    field :grammar, :type => Grammar, :inverse => Grammar.rules, :key => true
    field :arg, :type => Expression
  end

  klass Expression do
  end
    
  klass Alt, :super => Expression do
    field :alts, :type => Expression, :many => true
  end

  klass Sequence, :super => Expression do
    field :elements, :type => Expression, :optional => true, :many => true
  end

  klass Create, :super => Expression do
    field :name, :type => :str
    field :arg, :type => Expression
  end

  klass Field, :super => Expression do
    field :name, :type => :str
    field :arg, :type => Expression
  end
  
  klass Code, :super => Expression do
    field :code, :type => :str
  end

  klass Value, :super => Expression do
    field :kind, :type => :str
  end

  klass Ref, :super => Expression do
    field :name, :type => :str
  end

  klass Lit, :super => Expression do
    field :value, :type => :str
  end

  klass Call, :super => Expression do 
    field :rule, :type => Rule
  end

  klass Regular, :super => Expression do
    field :arg, :type => Expression
    field :optional, :type => :bool
    field :many, :type => :bool
    field :sep, :type => :str, :optional => true
  end

  SchemaSchema.finalize(schema)
end

if __FILE__ == $0 then

  require 'schema/schemaschema'
  require 'tools/print'
  
  Print.new.recurse(GrammarSchema.schema, SchemaSchema.print_paths)  
end

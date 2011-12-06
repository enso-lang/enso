
require 'core/system/boot/schema_gen'
require 'core/system/boot/schema_schema'

class GrammarSchema < SchemaGenerator
  primitive :str
  primitive :int
  primitive :bool
  primitive :atom

  klass Grammar do
    field :start, :type => Rule
    field :rules, :type => Rule, :optional => true, :many => true, :traversal => true
  end

  klass Rule, :super => Expression do
    field :name, :type => :str, :key => true
    field :grammar, :type => Grammar, :inverse => :rules , :key => true
    field :arg, :type => Expression, :traversal => true, :optional => true
  end

  klass Expression do
  end

  klass Epsilon, :super => Expression do
  end
    
  klass Alt, :super => Expression do
    field :alts, :type => Expression, :many => true, :traversal => true
  end

  klass Sequence, :super => Expression do
    field :elements, :type => Expression, :optional => true, :many => true, :traversal => true
  end

  klass Create, :super => Expression do
    field :name, :type => :str
    field :arg, :type => Expression, :traversal => true
  end

  klass Field, :super => Expression do
    field :name, :type => :str
    field :arg, :type => Expression, :traversal => true
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

  klass Ref2, :super => Expression do
    field :path, :type => Path, :traversal => true
  end

  klass Lit, :super => Expression do
    field :value, :type => :str
  end

  klass Call, :super => Expression do 
    field :rule, :type => Rule
  end

  klass Regular, :super => Expression do
    field :arg, :type => Expression, :traversal => true
    field :optional, :type => :bool
    field :many, :type => :bool
    field :sep, :type => :str, :optional => true
  end

  klass Item , do
    field :expression, :type => Expression
    field :elements, :type => Expression, :optional => true, :many => true
    field :dot, :type => :int
  end

  klass Key do
  end

  klass Const, :super => Key do
    field :value, :type => :atom
  end

  klass It, :super => Key do
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
    field :is_root, :type => :bool, :computed => "@parent == nil"
  end


  patch_schema_pointers(schema)
end

if __FILE__ == $0 then

  require 'core/schema/tools/print'
  
  Print.new.recurse(GrammarSchema.schema)  
end


require 'ostruct'

class SchemaModel #< BasicObject
  @@ids = 0

  attr_accessor :schema_class
#  attr_reader :_graph_id
	
  def initialize()
#     @_graph_id = OpenStruct.new
#     @_graph_id.schema = schema
    @data = {}
    @id = @@ids += 1
  end

  def internal_wrapped_value
    return self
  end

  def [](field_name)
    raise "undefined internal field #{field_name}" if field_name[0] == "_"
    if field_name[-1] == "?"
      return self.schema_class.name == field_name[0..-2]
    else
      sym = field_name.to_sym
      define_singleton_method(sym) do
        @data[field_name]
      end
      @data[field_name]
    end
  end

  def []=(field_name, v)
    raise "undefined internal field #{field_name}" if field_name[0] == "_"
    @data[field_name] = v
  end

  def method_missing(name, *args, &block)
    if (name.to_s =~ /^(.*)=$/)
      self[$1] = args[0]
    else
      return self[name.to_s]
    end
  end

  # NB: JRuby --1.9 requires this: in it Object#type still exists
  # (although deprecated) so our method_missing does not fire.
  def type
    self['type']
  end

  def to_s
    k = ClassKey(schema_class)
    "<BOOT #{schema_class.name} #{k ? self[k.name] : @_id}>"
  end

  def hash
    "boot#{_id}".hash
  end

  def nil?
    false
  end

  def _id
    return @id
  end

  def respond_to?(sym)
    return false
  end

  def inspect
    to_s
  end
end


class ValueHash < Hash
  include Enumerable
  def initialize(key = "name")
    @key = key
  end

  def each(&block)
    values.each &block
  end

  def <<(x)
    self[x[@key]] = x
  end

  # sligthly nonstandard zip, includes all elements of this and other
  def outer_join(other)
    keys = self.keys | other.keys
    #puts "JOIN: #{self} | #{other}"
    keys.each do |key_val|
      yield self[key_val], other[key_val], key_val
    end
  end

end

class SchemaGenerator
  ## NB: to use this schemagenerator, be careful with names of classes
  ## defined using klass(): if you use a name that collides with any name
  ## included in Kernel, it'll break. 
  ## Todo: fix this?

  class Wrap < BasicObject
    attr_reader :internal_wrapped_value
    def initialize(m, builder)
      @internal_wrapped_value = m
      @builder = builder
    end

    def method_missing(name, *args)
      @builder.get_field(@internal_wrapped_value, name.to_s)
    end
  end

  @@schemas = {}

  def self.inherited(subclass)
    schema = SchemaModel.new
    @@schemas[subclass.to_s] = schema
    schema.classes = ValueHash.new
    schema.primitives = ValueHash.new
    schema.types = ValueHash.new
    schema.sym_primitives = ValueHash.new
  end

  def self.schema
    @@schemas[self.to_s]
  end

  def self.schema=(schema)
    @@schemas[schema.name] = schema
  end
    

  class << self
    def primitive(name)
      m = SchemaModel.new
      m.name = name.to_s
      m.schema = schema
      schema.primitives[name.to_s] = m
      schema.types[name.to_s] = m
      schema.sym_primitives[name] = m
    end
      
    def klass(wrapped, opts = {}, &block)
      m = wrapped.internal_wrapped_value
      @@current = m
      super_class opts[:super] if opts[:super]
      yield
    end
    
    def super_class(klass)
      @@current.supers << klass.internal_wrapped_value
      @@current.supers.each do |sup|
        sup.subtypes << @@current
        sup.all_fields.each do |f|
          @@current.all_fields[f.name] = f 
        end    
      end    
    end

    def field(name, opts = {})
      f = get_field(@@current, name.to_s)
      t = opts[:type]
      f.type = schema.sym_primitives.keys.include?(t) ? \
         schema.sym_primitives[t] : t.internal_wrapped_value
      raise "Unknown type #{t}" unless f.type
      f.optional = opts[:optional] || false
      f.many = opts[:many] || false
      f.key = opts[:key] || false
      f.inverse = opts[:inverse]
      f.inverse.inverse = f if f.inverse
      f.computed = opts[:computed]
      f.traversal = opts[:traversal] || false
    end

    def const_missing(name)
      Wrap.new(get_class(name.to_s), self)
    end

    def get_field(klass, name)
      klass.defined_fields.each do |f|
        return f if f.name == name
      end
      f = SchemaModel.new
      #puts "Creating field #{name} (#{f._id})"
      f.name = name
      klass.defined_fields[name] = f
      klass.all_fields[name] = f
      f.owner = klass
      return f
    end

    def get_class(name)
      m = schema.classes[name]
      return m if m
      #puts "MAKEING CLASS #{name}"
      m = SchemaModel.new
      schema.classes[name] = m
      schema.types[name] = m
      #puts "TYPES #{schema.types.collect(&:name)}"
      #puts "Getting class #{name} (#{m._id})"
      m.name = name
      m.schema = schema
      m.fields = ValueHash.new
      m.defined_fields = ValueHash.new
      m.all_fields = ValueHash.new
      m.subtypes = ValueHash.new
      m.supers = ValueHash.new
      return m
    end
    
    def patch_schema_pointers(schema, schema_schema = SchemaSchema.schema)
      kschema = schema_schema.classes["Schema"]
      prim = schema_schema.types["Primitive"]
      klass = schema_schema.types["Klass"]
      field = schema_schema.types["Field"]
      
      # Yes, we are breaking encapsulation here. Necessary for bootstrapping
      schema.instance_eval { @schema_class = kschema}
      schema.primitives.each do |p|
        p.instance_eval { @schema_class = prim }
      end
      schema.classes.each do |c|
        c.instance_eval { @schema_class = klass }
        c.defined_fields.each do |f|
          f.instance_eval { @schema_class = field }
        end
        c.all_fields.each do |f|
          c.fields << f if !f.computed
        end
      end
    end
    
    
  end

end

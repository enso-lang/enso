=begin

Re-implementation of delta tranformation using Ruby's ERB

=end

require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/grammar/render/layout'
require 'core/system/library/schema'
require 'erb'

class DeltaERB
  SCHEMA_SCHEMA = Loader.load('schema.schema')
  DELTA_ERB = File.join(File.dirname(__FILE__), 'delta.erb')

  def self.delta(schema, factory = ManagedData.new(SCHEMA_SCHEMA))
    self.new(schema, factory).delta
  end
    
  def initialize(schema, factory)
    @schema = schema
    @factory = factory
  end

  def delta
    ds = gen_delta_as_string(@schema)
    Loader.load_text('schema', @factory, ds)
  end

  def gen_delta_as_string(schema)
    template_string = File.read(DELTA_ERB)
    template = ERB.new(template_string)
    ds = template.result(binding) 
    return ds
  end  

  def extends_clause(type)
    return '' if type.supers.empty?
    sups = type.supers.map { |s| "D_#{s.name}" }
    return " < #{sups.join(', ')}"
  end

  def delta_name(type)
    "D_#{type.name}"
  end

  def mult(f)
    f.many ? '*' : '?'
  end

  def delta_ref(op = '')
    stem = 'DeltaRef'
    stem = "#{op}_#{stem}" unless op.empty?
    return stem
  end

  def many_delta_ref(name, op = '')
    "Many#{delta_ref(op)}#{name}"
  end

  def op_delta(name, op)
    "#{op}_#{name}"
  end

  def key_many_delta_ref(type)
    many_delta_ref(ClassKey(type).type.name)
  end

  def field_delta_type(f)
    return delta_name(f.type) if f.traversal || f.type.Primitive? 
    return delta_ref unless f.many
    return key_many_delta_ref(f.type) if IsKeyed?(f.type)
    return many_delta_ref('int')
  end

  def keyed
    'Keyed'
  end

  def many
    'Many'
  end

  def key_super(type)
    IsKeyed?(type) ? keyed : many
  end

  def pos_key(type)
    IsKeyed?(type) ? ClassKey(type).type.name : 'int'
  end

end



require 'core/system/library/schema'
require 'core/schema/code/finalize'
require 'core/system/utils/paths'
require 'ostruct'


## TODO: paths

module ManagedData

  class Factory
    attr_reader :schema

    def initialize(schema)
      @schema = schema
      schema.classes.each do |cls|
        __constructor(cls)
      end
    end

    def [](name)
      send(name)
    end

    private

    def __constructor(klass)
      define_singleton_method(klass.name) do |*args|
        MObject.new(klass, self, *args)
      end
    end
  end    

  
  class DynamicUpdateProxy
    def initialize(obj)
      @obj = obj
      @fields = {}
    end
    
    def method_missing(m, *args)
      if m =~ /(.*)=/
        @obj[$1] = args[0]
      else
        name = m.to_s
        var = @fields[name]
        return var if var
        val = @obj[name]
        @fields[name] = var = Variable.new("#{@obj}.#{name}", val)
        @obj.add_listener name do |val|
          var.value = val
        end
        return var
      end
    end
  end
  
  
  class MObject 
    attr_accessor :_origin
    attr_accessor :_path
    attr_reader :_id
    attr_reader :_graph_id
    attr_reader :schema_class

    @@_id = 0
    
    def initialize(klass, factory, *args)
      @_id = @@_id += 1
      @schema_class = klass
      @_graph_id = factory
      @hash = {}
      @listeners = {}
      __setup(klass.all_fields)
      __init(klass.fields, args)
      __install(klass.all_fields)
    end

    def method_missing(sym, *args, &block)
      if sym =~ /^([A-Z].*)\?$/
        schema_class.name == $1
      else
        super(sym, *args, &block)
      end
    end

    def [](name)
      check_field(name, true)
      if computed?(name)
        send(name)
      else
        __get(name).get 
      end
    end

    def []=(name, x)
      check_field(name, false)
      __get(name).set(x)
    end

    def dynamic_update
      @dyn ||= DynamicUpdateProxy.new(self)
    end

    def add_listener(name, &block)
      @listeners[name] ||= []
      @listeners.push(block)
    end

    def notify(name, obj)
      return unless @listeners[name]
      @listeners[name].each do |blk|
        blk.call(new)
      end
    end

    def _origin_of(name); __get(name)._origin end

    def __get(name); @hash[name] end

    def __set(name, fld); @hash[name] = fld end

    def eql?(o); self == o end

    def ==(o)
      return false if o.nil?
      return false unless o.is_a?(MObject)
      _id == o._id 
    end

    def hash; _id end

    def to_s
      k = ClassKey(schema_class)
      if k then
        "<<#{schema_class.name} #{_id} '#{self[k.name]}'>>"
      else
        "<<#{schema_class.name} #{_id}>>"
      end
    end

    def finalize
      # nothing for now
      self
    end

    private


    def check_field(name, can_be_computed)
      #if !schema_class.all_fields[name] then
      # ^^^^ does not terminate
      if !@hash.include?(name) then
        raise "Non-existing field '#{name}' for #{self}"
      end
      if !can_be_computed && computed?(name) then
        raise "Cannot assign to computed field '#{name}'"
      end
    end

    def computed?(name)
      __get(name) == :computed
    end

    def __setup(fields)
      fields.each do |fld|
        if fld.computed then
          __set(fld.name, :computed)
        elsif fld.type.Primitive? then
          __set(fld.name, Prim.new(self, fld))
        elsif !fld.many then
          __set(fld.name, Ref.new(self, fld))
        elsif key = ClassKey(fld.type) then
          __set(fld.name, Set.new(self, fld, key))
        else
          __set(fld.name, List.new(self, fld))
        end
      end
    end

    def __init(fields, args)
      # NB: this works because ruby 1.9 hashes maintain
      # insertion order, so the order of iteration will
      # be the order of occurence in the model
      fields.each_with_index do |fld, i|
        break if i >= args.length
        __get(fld.name).init(args[i])
      end
    end

    def __install(fields)
      fields.each do |fld|
        if fld.computed then
          __computed(fld.name, fld.computed.gsub(/@/, 'self.'))
        else
          __setter(fld.name)
          __getter(fld.name)
        end
      end
    end

    def __computed(name, exp)
      define_singleton_method(name) do 
        instance_eval(exp)
      end
    end

    def __setter(name)
      define_singleton_method("#{name}=") do |arg|
        self[name] = arg
      end
    end

    def __getter(name)
      define_singleton_method(name) do 
        self[name]
      end
    end

  end

  class Field 
    def initialize(owner, field)
      @owner = owner
      @field = field
    end

    def to_s; ".#{@field.name} = #{@value}" end
  end

  class Single < Field
    # fields have origins for primitives
    # and cross refs. For spine refs
    # this origin is the same as the origin
    # of the mobject pointed to
    attr_accessor :_origin

    def initialize(owner, field)
      super(owner, field)
      @value = default
    end

    def set(value)
      check(value)
      @value = value
    end

    def get; @value end
    
    def init(value); set(value) end

    def default; nil end
  end

  class Prim < Single

    def check(value)
      return if value.nil? && @field.optional
      case @field.type.name 
      when 'str' then 
        return if value.is_a?(String)
      when 'int' 
        return if value.is_a?(Integer)
      when 'bool' 
        return if value.is_a?(TrueClass) || value.is_a?(FalseClass)
      when 'float' 
        return if value.is_a?(Numeric)
      when 'datetime' 
        return if value.is_a?(DateTime)
      when 'atom' 
        return
      end
      raise "Invalid value for #{@field.type.name}: #{value}"
    end

    def default
      return nil if @field.optional
      case @field.type.name
      when 'str' then ''
      when 'int' then 0
      when 'bool' then false
      when 'float' then 0.0
      when 'datetime' then DateTime.now
      when 'atom' then nil
      else
        raise "Unknown primitive type: #{@field.type.name}"
      end
    end
  end

  module RefHelpers
    def notify(old, new)
      @owner.notify(@field.name, new)
      return unless @field.inverse
      if @field.inverse.many then
        # old and new are both collections
        old.__get(@field.inverse.name).__delete(@owner) if old
        new.__get(@field.inverse.name).__insert(@owner) if new
      else
        # old and new are both mobjs
        old.__get(@field.inverse.name).__set(nil) if old
        new.__get(@field.inverse.name).__set(@owner) if new
      end
    end

    def check(mobj)
      return if mobj.nil? && @field.optional
      if mobj.nil? then
        raise "Cannot assign nil to non-optional field #{@field.name}"
      end
      if !Subclass?(mobj.schema_class, @field.type) then
        raise "Invalid type for #{@field.name}: #{mobj.schema_class.name}"
      end
      if mobj._graph_id != @owner._graph_id then
        raise "Inserting object #{mobj} into the wrong model"
      end
    end
  end

  class Ref < Single
    include RefHelpers

    def set(value)
      check(value)
      notify(get, value)
      __set(value)
    end

    def __set(value)
      @value = value
    end
  end


  class Many < Field
    include RefHelpers
    include Enumerable

    def get
      self # collection wrappers are exposed to outside
    end

    def set
      raise "Cannot assign to many-valued field #{@field.name}"
    end

    def init(values)
      values.each do |value|
        self << value
      end
    end

    def [](key); @value[key] end

    def empty?; @value.empty? end

    def length; @value.length end

    def to_s; @value.to_s end

    # override check and notify
    # so that they are not called
    # on disconnected collections

    def check(mobj)
      return if !connected?
      super(mobj)
    end

    def notify(old, new)
      return if !connected?
      super(old, new)
    end

    def connected?
      @field && @owner
    end
  end

  class Set < Many
    def initialize(owner, field, key)
      super(owner, field)
      @value = {}
      @key = key
    end

    def each(&block)
      @value.each_value(&block)
    end


    ### These are readonly "queries", so we return
    ### disconnected Sets (no field, no owner)

    def +(other)
      check_key_field(__key, other.__key)
      r = self.inject(Set.new(nil, nil, __key || other.__key), &:<<)
      other.inject(r, &:<<)
    end

    def select(&block)
      result = Set.new(nil, nil, __key)
      each do |elt|
        result << elt if yield elt
      end
      return result
    end

    def flat_map(&block)
      new = nil
      each do |x|
        set = yield x
        if new.nil? then
          key = set.__key
          new = Set.new(nil, nil, key)
        else
          check_key_field(key, set.__key)
        end
        set.each do |y|
          new << y
        end
      end
      new || Set.new(nil, nil, nil)
    end
      
    def outer_join(other)
      keys = __keys | other.__keys
      keys.each do |key|
        yield self[key], other[key], key
      end
    end

    def to_ary; @value.values end

    def <<(mobj)
      check(mobj)
      key = mobj[@key.name]
      raise "Nil key when adding #{mobj} to #{@field.name}" unless key
      return self if @value[key] == mobj
      raise "Duplicate key #{key}" if @value[key]
      notify(@value[key], mobj)
      __insert(mobj)
      return self
    end

    def delete(mobj)
      key = mobj[@key.name]
      return unless @value.include_key?(key)
      notify(@value[key], nil)
      __delete(mobj)
    end

    def __key; @key end

    def __keys; @value.keys end

    def __insert(mobj)
      @value[mobj[@key.name]] = mobj
    end

    def __delete(mobj)
      @value.delete(mobj[@key.name])
    end

    private

    def check_key_field(key1, key2)
      # key can be nil for empty sets
      return if key1.nil? || key2.nil?
      if key1 != key2 then
        raise "Incompatible key fields: #{key1} vs #{key2}" 
      end
    end

  end

  class List < Many
    def initialize(owner, field)
      super(owner, field)
      @value = []
    end

    def each(&block)
      @value.each(&block)
    end

    def <<(mobj)
      check(mobj)
      notify(nil, mobj)
      __insert(mobj)
      return self
    end

    def delete(mobj)
      deleted = __delete(mobj)
      notify(deleted, nil) if deleted
      return deleted
    end

    def __insert(mobj); @value << mobj end

    def __delete(mobj); @value.delete(mobj) end
  end  
end


if __FILE__ == $0 then
  require 'core/system/load/load'
  require 'core/schema/tools/print'
  M = ManagedData
  ss = Loader.load('schema.schema')
  fact = M::Factory.new(ss)
  s = fact.Schema
  c = fact.Class('Foo')
  c.schema = s
  p = fact.Primitive('str')
  p.schema = s
  f = fact.Field('bla', c, p, true, false, false)
  f.type = p
  puts f.name
  # c.defined_fields << f

  puts c
  puts c.name
  c.fields.each do |fld|
    puts "FLD: #{fld}"
    puts "OWNER: #{fld.owner}"
    puts "TYPE: #{fld.type}"
  end
  Print.print(s)
end

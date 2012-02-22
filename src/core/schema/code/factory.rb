
require 'core/schema/code/many'
require 'core/schema/code/dynamic'
require 'core/system/utils/paths'
require 'core/system/library/schema'
require 'core/semantics/code/interpreter'
require 'core/expr/code/eval'

=begin

Coding convention

- private methods: private to the class (ordinary Ruby semantics)
- __method: to be only used by classes in ManagedData
- _method: to be used outside, but internal meta data (e.g. origin/path)

=end


module ManagedData
  class Factory
    attr_reader :schema, :interp

    def initialize(schema, interp=nil)
      @schema = schema
      @interp = interp || Interpreter(FactorySchema)
      @interp.compose!(EvalExpr)
      @roots = []
      __constructor(schema.types)
    end

    def [](name); send(name) end

    def register(root)
      # perhaps raise exception if more than one?
      # (NB any object will always be in the spine of 1 root anyway)
      @roots << root
    end

    def delete!(obj)
      @roots.each do |root|
        root.__delete_obj(obj)
      end
    end

    attr_accessor :file_path

    private

    def __constructor(klasses)
      klasses.each do |klass|
        define_singleton_method(klass.name) do |*args|
          @interp.Make(klass, :args=>args, :factory=>self)
        end
      end
    end

  end

  class MObject
    attr_accessor :_origin # source location
    attr_accessor :__shell # spine parent (e.g. Ref, Set or List)
    attr_reader :_id
    attr_reader :factory
    attr_reader :schema_class

    @@_id = 0

    def initialize(klass, factory, *args)
      @_id = @@_id += 1
      @schema_class = klass
      @factory = factory
      @interp = factory.interp
      @hash = {}
      @listeners = {}
      __setup(klass.all_fields)
      __init(klass.fields, args)
      __install(klass.all_fields)
    end

    # TODO: get rid of this
    def method_missing(sym, *args, &block)
      # $stderr << "WARNING: method_missing #{sym}\n"
      if sym =~ /^([A-Z].*)\?$/
        schema_class.name == $1
      else
        super(sym, *args, &block)
      end
    end

    def _graph_id; @factory end

    def instance_of?(sym)
      schema_class.name == sym.to_s
    end

    def [](name)
      check_field(name, true)
      computed?(name) ? send(name) : __get(name).get
    end

    def []=(name, x)
      check_field(name, false)
      __get(name).set(x)
    end

    def delete!; factory.delete!(self) end

    def __delete_obj(mobj)
      # traverse down spine until found, then delete!
      # (called from factory)
      schema_class.fields.each do |fld|
        if fld.traversal then
          __get(fld.name).__delete_obj(mobj)
        end
      end
    end

    def dynamic_update
      @dyn ||= DynamicUpdateProxy.new(self)
    end

    def add_listener(name, &block)
      (@listeners[name] ||= []).push(block)
    end

    def notify(name, val)
      return unless @listeners[name]
      @listeners[name].each do |blk|
        blk.call(val)
      end
    end

    def _origin_of(name); __get(name)._origin end

    def _set_origin_of(name, org)
      __get(name)._origin = org
    end

    def _path_of(name); _path.field(name) end

    def _path
      __shell ? __shell._path(self) : Paths::Path.new
    end

    def _clone
      r = MObject.new(@schema_class, @factory)
      schema_class.fields.each do |field|
        if field.many
          self[field.name].each do |o|
            r[field.name] << o
          end
        else
          #puts "CLONE #{field.name} #{self[field.name]}"
          r[field.name] = self[field.name]
        end
      end
      return r
    end
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
      # TODO: check required fields etc.
      factory.register(self)
      self
    end

    private

    def check_field(name, can_be_computed)
      if !@hash.include?(name) then
        raise "Non-existing field '#{name}' for #{self}"
      end
      if !can_be_computed && computed?(name) then
        raise "Cannot assign to computed field '#{name}'"
      end
    end

    def computed?(name); __get(name) == :computed end

    def __setup(fields)
      fields.each do |fld|
        __set(fld.name, @interp.Make(fld, :class=>self))
      end
    end

    def __init(fields, args)
      fields.each_with_index do |fld, i|
        break if i >= args.length
        __get(fld.name).init(args[i])
      end
    end

    def __install(fields)
      fields.each do |fld|
        if fld.computed then
          __computed(fld.name, fld.computed)
        else
          __setter(fld.name)
          __getter(fld.name)
        end
      end
    end

    def __computed(name, exp)
      define_singleton_method(name) do
        if exp.is_a? String # FIXME: this case is needed to parse bootstrap schema
          instance_eval(exp.gsub(/@/, 'self.'))
        elsif exp.EStrConst?
          instance_eval(exp.val.gsub(/@/, 'self.'))
        else
          @interp.eval(exp, :env=>Env.new({}, Env.new(self)))
        end
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
    # fields have origins for primitives, spine refs
    # and cross refs. For spine refs
    # this origin is the same as the _origin
    # of the mobject pointed to.
    attr_accessor :_origin

    def initialize(owner, field)
      @owner = owner
      @field = field
    end

    def __delete_obj(mobj)
      # default: do nothing
    end

    def to_s; ".#{@field.name} = #{@value}" end
  end

  class Single < Field
    def initialize(owner, field)
      super(owner, field)
      @value = default
    end

    def set(value)
      check(value)
      @value = value
      @owner.notify(@field.name, value)
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
      when 'real'
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
      when 'real' then 0.0
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
      if @field.traversal then
        value.__shell = self if value
        get.__shell = nil if get && !value
      end
      @value = value
    end

    def _path(_)
      @owner._path.field(@field.name)
    end

    def __delete_obj(mobj)
      if get == mobj then
        set(nil) # set takes case of inverses
      end
    end
  end


  class Many < Field
    include RefHelpers
    include Enumerable

    def get; self end

    def set
      raise "Cannot assign to many-valued field #{@field.name}"
    end

    def init(values)
      values.each do |value|
        self << value
      end
    end

    def __value; @value end

    def [](key); __value[key] end

    def empty?; __value.empty? end

    def length; __value.length end

    def to_s; __value.to_s end

    def clear; __value.clear end

    def connected?; @owner end

    def check(mobj)
      return if !connected?
      super(mobj)
    end

    def notify(old, new)
      return if !connected?
      super(old, new)
    end

    def __delete_obj(mobj)
      if values.include?(mobj) then
        delete(mobj)
      end
    end

    def connect(mobj, shell)
      if connected? && @field.traversal then
        mobj.__shell = shell
      end
    end
  end

  class Set < Many
    include SetUtils

    def initialize(owner, field, key)
      super(owner, field)
      @value = {}
      @key = key
    end

    def each(&block); __value.each_value(&block) end

    def each_pair(&block); __value.each_pair &block end

    def values; __value.values end

    def keys; __value.keys end

    #FIXME: poor programming practise but necessary
    # to support key changes in object
    def _recompute_hash!
      nval = {}
      @value.each do |k,v|
        nval[v[@key.name]] = v
      end
      @value = nval
      self
    end

    def <<(mobj)
      check(mobj)
      key = mobj[@key.name]
      raise "Nil key when adding #{mobj} to #{self}" unless key
      return self if @value[key] == mobj
      raise "Duplicate key #{key}" if @value[key]
      notify(@value[key], mobj)
      __insert(mobj)
      return self
    end

    def delete(mobj)
      key = mobj[@key.name]
      return unless @value.has_key?(key)
      notify(@value[key], nil)
      __delete(mobj)
    end

    def _path(mobj)
      @owner._path.field(@field.name).key(mobj[@key.name])
    end

    def __insert(mobj)
      connect(mobj, self)
      @value[mobj[@key.name]] = mobj
    end

    def __delete(mobj)
      deleted = @value.delete(mobj[@key.name])
      connect(deleted, nil)
      return deleted
    end

  end

  class List < Many
    include ListUtils

    def initialize(owner, field)
      super(owner, field)
      @value = []
    end

    def [](key); __value[key.to_i] end

    def each(&block); __value.each(&block) end

    def each_pair(&block)
      __value.each_with_index do |item, i|
        block.call(i, item)
      end
    end

    def values; __value end

    def keys; Array.new(length){|i|i} end

    def <<(mobj)
      raise "Cannot insert nil into list" if !mobj
      check(mobj)
      notify(nil, mobj)
      __insert(mobj)
      return self
    end

    def delete(mobj)
      deleted = __delete(mobj)
      notify(deleted, nil)  if deleted
      return deleted
    end

    def _path(mobj)
      @owner._path.field(@field.name).index(@value.index(mobj))
    end

    def __insert(mobj)
      connect(mobj, self)
      @value << mobj
    end

    def __delete(mobj)
      deleted = @value.delete(mobj)
      connect(deleted, nil)
      return deleted
    end
  end
end


module FactorySchema
  include ManagedData

  def Make_Schema(args=nil)
    Factory.new(args[:self], self)
  end

  def Make_Class(args=nil)
    MObject.new(args[:self], args[:factory], *args[:args])
  end

  def Make_Field(computed, many, type, args=nil)
    fld = args[:self]
    klass = args[:class]
    if computed then
      :computed
    elsif type.Primitive? then
      ManagedData::Prim.new(klass, fld)
    elsif !many then
      ManagedData::Ref.new(klass, fld)
    elsif key = ClassKey(type) then
      ManagedData::Set.new(klass, fld, key)
    else
      ManagedData::List.new(klass, fld)
    end
  end
end




if __FILE__ == $0 then
  require 'core/system/load/load'
  require 'core/schema/tools/print'
  M = ManagedData
  ss = Loader.load('schema.schema')
  fact = M::Factory.new(ss)
  puts "Schema"
  s = fact.Schema
  puts "CLass FOO"
  c = fact.Class('Foo')
  puts "c.schema = s"
  c.schema = s

  puts "Primitiv str"
  p = fact.Primitive('str')

  puts "p.schema = s"
  p.schema = s

  puts "field 'bla' c = owner, p is type"
  f = fact.Field('bla', c, p, true, false, false)

  puts "f.type = p"

  f.type = p
  puts f.name
  # c.defined_fields << f
  s = s.finalize
  puts c
  puts c.name
  c.fields.each do |fld|
    puts "FLD: #{fld}"
    puts "OWNER: #{fld.owner}"
    puts "TYPE: #{fld.type}"
  end
  Print.print(s)

  ss.classes.each do |cls|
    puts cls._origin
    puts "PATH = #{cls._path}"
    cls.fields.each do |fld|
      puts "\tFIELD PATH = #{fld._path}"
      ss.classes['Field'].fields.each do |f|
        org = fld._origin_of(f.name)
        path = fld._path_of(f.name)
        puts "\t#{f.name}: #{org}" if org
        puts "\t#{f.name}: #{path}"
      end
    end
 end
end

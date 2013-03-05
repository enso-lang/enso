
require 'core/schema/code/dynamic'
require 'core/system/utils/paths'
require 'core/system/library/schema'
require 'core/semantics/code/interpreter'
require 'core/expr/code/impl'
require 'core/expr/code/env'
require 'core/expr/code/freevar'

=begin

Coding convention

- private methods: private to the class (ordinary Ruby semantics)
- __method: to be only used by classes in ManagedData
- _method: to be used outside, but internal meta data (e.g. origin/path)

=end


module Factory
  def self.new(schema)
    SchemaFactory.new(schema)
  end

  class SchemaFactory
    attr_reader :schema
    attr_accessor :file_path

    def initialize(schema)
      @schema = schema
      @roots = []
      @file_path = []
      schema.classes.each do |klass|
        define_singleton_method(klass.name) do |*args|
         MObject.new(klass, self, *args)
        end 
      end
    end
    
    def [](name)
      send(name)
    end
    
    def register(root)
      #raise "Creating two roots" if @root
      @root = root
    end
  end

  class MObject < EnsoProxyObject
    attr_accessor :_origin # source location
    attr_accessor :__shell # spine parent (e.g. Ref, Set or List)
    attr_reader :_id
    attr_reader :factory
    attr_accessor :extra_instance_data
    attr_reader :props

    @@_id = 0

    def initialize(klass, factory, *args)
      @_id = @@_id += 1
      @listeners = {}
      @props = {}
      
      # define accessors and updators
      define_singleton_value(:schema_class, klass)
      # setup
      @factory = factory
      __is_a(klass)
      __to_s(klass)
      # create the fields
      klass.all_fields.each do |fld|
        __setup(fld)
      end
      # initialize    
      klass.fields.each_with_index do |fld, i|
        if i < args.size
          if fld.many then
            args[i].each do |value|
              self[fld.name] << value
            end
          else
            self[fld.name] = args[i]
          end
        end
      end
    end
    
    def __setup(fld)
      if fld.computed then
        __computed(fld)
      elsif !fld.many then
        if fld.type.Primitive?
          prop = Prim.new(self, fld)
        else
          prop = Ref.new(self, fld)
        end
        @props[fld.name] = prop
        define_getter(fld.name, prop)
        define_setter(fld.name, prop)
      else
        if key = Schema::class_key(fld.type)
          collection = Set.new(self, fld, key)
        else
          collection = List.new(self, fld)
        end
        @props[fld.name] = collection
        define_singleton_value(fld.name, collection)
      end
    end

    def __get(name)
      @props[name]
    end

    def __is_a(klass)
      klass.schema.classes.each do |cls|
        val = Schema.subclass? klass, cls
        define_singleton_value("#{cls.name}?", val)
      end
    end
        
    def __to_s(cls)
      k = Schema::class_key(cls) || cls.fields.find{|f| f.type.Primitive? }
      if k then
        define_singleton_method :to_s do
          "<<#{cls.name} #{self._id} '#{self[k.name]}'>>"
        end
      else
        define_singleton_value(:to_s, "<<#{cls.name} #{self._id}>>")
      end
    end
    
    def __computed(fld)
      # check if this is a computed override of a field
      if fld.computed.EList? && (c = fld.owner.supers.find {|c| c.all_fields[fld.name]})
        #puts "LIST #{fld.name} overrides #{c.name}"
        base = c.all_fields[fld.name]
        if base.inverse
          fld.computed.elems.each do |var|
            raise "Field override #{fld.name} includes non-var #{var}" if !var.EVar?
            __get(var.name)._set_inverse = base.inverse
          end
        end
      end
      name = fld.name
      exp = fld.computed
      fvInterp = Freevar::FreeVarExprC.new
      commInterp = Impl::EvalCommandC.new
      val = nil
      define_singleton_method(name) do
        if val.nil?
          fvs = fvInterp.dynamic_bind env: Env::ObjEnv.new(self), bound: [] do
            fvInterp.depends(exp)
          end
          fvs.each do |fv|
            if fv.object  #should always be non-nil since computed fields have no external env
              fv.object.add_listener(fv.index) { val = nil }
            end
          end
          val = commInterp.dynamic_bind env: Env::ObjEnv.new(self), for_field: fld do
            commInterp.eval(exp)
          end
          #puts "COMPUTED #{name}=#{val}"
        end
        val
      end
    end

    def _graph_id; @factory end

    def instance_of?(sym)
      schema_class.name == sym.to_s
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
      @dyn ||= Dynamic::DynamicUpdateProxy.new(self)
    end

    def add_listener(name, &block)
      listeners = @listeners[name]
      listeners = @listeners[name] = [] if !listeners
      listeners.push(block)
    end

    def notify(name, val)
      if @listeners[name]
        @listeners[name].each do |blk|
          blk.call(val)
        end
      end
    end

    def _origin_of(name); __get(name)._origin end

    def _set_origin_of(name, org)
      __get(name)._origin = org
    end

    def _path_of(name); _path.field(name) end

    def _path
      __shell ? __shell._path(self) : Paths::new
    end

    def _clone
      r = MObject.new(schema_class, @factory)
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
      r
    end

    def eql?(o); self == o end

    def equals(o)
      o && o.is_a?(MObject) && _id == o._id
    end

    def hash; @_id end

    def finalize
      # TODO: check required fields etc.
      factory.register(self)
      self
    end

    #private

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
      @inverse = field.inverse if field # might get overriden!!
    end

    def _set_inverse=(inv)
      raise "Overiding inverse of field '#{inv.owner.name}.#{invk.name}'" if @inverse
      @inverse = inv
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
      if !@field.optional || value 
        ok = case @field.type.name
        when 'str' then
          value.is_a?(String)
        when 'int'
          value.is_a?(Integer)
        when 'bool'
          value.is_a?(TrueClass) || value.is_a?(FalseClass)
        when 'real'
          value.is_a?(Numeric)
        when 'datetime'
          value.is_a?(DateTime)
        when 'atom'
          value.is_a?(Numeric) || value.is_a?(String) || value.is_a?(TrueClass) || value.is_a?(FalseClass)
        end
        raise "Invalid value for #{@field.name}:#{@field.type.name} = #{value}" if !ok 
      end
    end

    def default
      if !@field.optional
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
  end

  module SetUtils
    def to_ary; @values.values end

    def union(other)
      # left-biased: field is from self
      result = Set.new(nil, @field, __key || other.__key)
      self.each do |x|
        result << x
      end
      other.each do |x|
        result << x
      end
      result
    end

    def select(&block)
      result = Set.new(nil, @field, __key)
      each do |elt|
        result << elt if block.call(elt)
      end
      result
    end

    def flat_map(&block)
      new = nil
      each do |x|
        set = block.call(x)
        if new.nil? then
          key = set.__key
          new = Set.new(nil, @field, key)
        end
        set.each do |y|
          new << y
        end
      end
      new || Set.new(nil, @field, __key)
    end
      
    def each_with_match(other, &block)
      empty = Set.new(nil, @field, __key)
      __outer_join(other || empty) do |sa, sb|
        if sa && sb && sa[__key.name] == sb[__key.name] 
          block.call(sa, sb)
        elsif sa
          block.call(sa, nil)
        elsif sb
          block.call(nil, sb)
        end
      end
    end

    def __key; @key end

    def __keys; @value.keys end

    def __outer_join(other, &block)
      keys = __keys.union(other.__keys)
      keys.each do |key|
        block.call( self[key], other[key], key )
        # block.call( self.get_maybe(key), other.get_maybe(key), key )   # allow non-defined fields to merge
      end
    end
  end

  module ListUtils
    def each_with_match(other, &block)
      if !empty? then
        each do |item|
          block.call( item, nil )
        end
      end
    end
  end
  
  module RefHelpers
    def notify(old, new)
      #puts "NOTIFY #{new} / #{@inverse}" if @inverse  # @field.name == "rules"
      if old != new
        @owner.notify(@field.name, new)
        if @inverse
          if @inverse.many then
            # old and new are both collections
            #puts "INVERSE #{old}.#{@inverse.name} DEL #{@owner}" if old
            #puts "INVERSE #{new}.#{@inverse.name} << #{@owner}" if new
            old.__get(@inverse.name).__delete(@owner) if old
            new.__get(@inverse.name).__insert(@owner) if new
          else
            #puts "INVERSE #{old}.#{@inverse.name} = #{@owner}" if old
            #puts "INVERSE #{new}.#{@inverse.name} = #{@owner}" if new
            # old and new are both mobjs
            old.__get(@inverse.name).__set(nil) if old
            new.__get(@inverse.name).__set(@owner) if new
          end
        end
      end
    end

    def check(mobj)
      if mobj || !@field.optional
        if mobj.nil? then
          raise "Cannot assign nil to non-optional field #{@field.name}"
        end
        if !Schema::subclass?(mobj.schema_class, @field.type) then
          raise "Invalid value for '#{@field.owner.name}.#{@field.name}': #{mobj} : #{mobj.schema_class.name}"
        end
        if mobj._graph_id != @owner._graph_id then
          raise "Inserting object #{mobj} into the wrong model"
        end
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

    def size; __value.size end

    def to_s; __value.to_s end

    def clear; __value.clear end

    def connected?; @owner end

    def has_key?(key); keys.include?(key) end

    def check(mobj)
      if connected?
        super(mobj)
      end
    end

    def notify(old, new)
      if connected?
        super(old, new)
      end
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
    
    def to_s
      "<MANY #{map{|x| x.to_s}}>"
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
    def find_first_pair(&block); __value.find_first_pair &block end

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
      if @value[key] != mobj
        delete(@value[key]) if @value[key]
        #raise "Duplicate key #{key}" if @value[key]
        notify(@value[key], mobj)
        __insert(mobj)
      end
      self
    end
    
    def []=(index, mobj)
      self<<(mobj)
    end

    def delete(mobj)
      key = mobj[@key.name]
      if @value.has_key?(key)
        notify(@value[key], nil)
        __delete(mobj)
      end
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
      deleted
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

    def keys; Array.new(size){|i|i} end

    def <<(mobj)
      raise "Cannot insert nil into list" if !mobj
      check(mobj)
      notify(nil, mobj)
      __insert(mobj)
      self
    end
    
    def []=(index, mobj)
      if !mobj
        raise "Cannot insert nil into list"
      end 
      old = __value[index.to_i]
      if old != mobj
        check(mobj)
        notify(nil, mobj)
        __value[index.to_i] = mobj
        notify(old, nil) if old
      end
      self
    end

    def delete(mobj)
      deleted = __delete(mobj)
      notify(deleted, nil)  if deleted
      deleted
    end

    def insert(index, mobj)
      if !mobj
        raise "Cannot insert nil into list"
      end 
      check(mobj)
      notify(nil, mobj)
      @value.insert(index.to_i, mobj)
      self
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
      deleted
    end
  end
end

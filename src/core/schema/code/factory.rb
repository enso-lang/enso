
require 'core/system/library/cyclicmap'
require 'core/system/library/schema'
require 'core/schema/code/finalize'

class Factory
  def initialize(schema)
    @schema = schema
  end

  # this is the core object constructor call
  # create a "virtual" object that conforms to schema class
  def [](class_name)
    schema_class = @schema.classes[class_name.to_s]
    raise "Unknown class '#{class_name}'" unless schema_class
    obj = CheckedObject.new(schema_class, self)
    return obj
  end

  # factory.Foo(args) creates an instance of Foo initialized with arguments  
  def method_missing(class_name, *args)
    obj = self[class_name.to_s]
    n = 0
    #puts "#{obj.schema_class.fields.keys}"
    obj.schema_class.fields.each do |field|
      #puts "FIELD: #{field}"
      if n < args.length
        if field.many
          col = obj[field.name]
          args[n].each do |x|
            col << x
          end
        else
          obj[field.name] = args[n]
        end
      elsif !field.key && !field.optional && field.type.Primitive?
        obj[field.name] = case field.type.name
                          when "str" then ""
                          when "int" then 0
                          when "bool" then false
                          end
      end
      n += 1
    end
    raise "too many constructor arguments supplied for '#{class_name}" if n < args.length
    return obj
  end
end

class CheckedObject

  attr_reader :schema_class
  attr_reader :_id
  @@_id = 0
  
  def _graph_id
    @factory
  end
  
  def initialize(schema_class, factory) #, many_index, many, int, str, b1, b2)
    @_id = @@_id += 1
    @hash = {}
    @schema_class = schema_class
    @factory = factory
    schema_class.fields.each do |field|
      if field.many
        # TODO: check for primitive many-valued???
        key = ClassKey(field.type)
        if key
          @hash[field.name] = ManyIndexedField.new(key.name, self, field)
        else
          @hash[field.name] = ManyField.new(self, field)
        end
      end
    end
  end
  
  def hash
    @_id
  end
  
  def ==(other)
    return false if other.nil?
    return false unless other.is_a?(CheckedObject)
    return _id == other._id
  end
  
  def nil?
    false
  end
  
  def [](field_name)
    if field_name[-1] == "?"
      return @schema_class.name == field_name[0..-2]
    end
    field = @schema_class.all_fields[field_name]; 
    raise "Accessing non-existant field '#{field_name}' of #{self} of class #{self.schema_class}" unless field

    sym = field.name.to_sym
    if field.computed
      exp = field.computed.gsub(/@/, "self.")
      define_singleton_method(sym) do
        instance_eval(exp)
      end
    else
      define_singleton_method(sym) do
        @hash[field_name]
      end
    end
    return send(sym)
  end

  def []=(field_name, new)
    #puts "Setting #{field_name} to #{new}"
    field = @schema_class.fields[field_name]
    raise "Assign to invalid field '#{field_name}' of #{self}" unless field
    raise "Can't set computed field '#{field_name}' of #{self}" if field.computed
    raise "Can't assign a many-valued field '#{field_name}' of #{self}" if field.many
    if new.nil?
      raise "Can't assign nil to required field '#{field_name}' of #{self}" if !field.optional
    else
      case field.type.name
      when "str" then raise "Attempting to assign #{new.class} #{new} to string field '#{field.name}'" unless new.is_a?(String)
      when "int" then raise "Attempting to assign #{new.class} #{new} to int field '#{field.name}'" unless new.is_a?(Integer)
      when "bool" then raise "Attempting to assign #{new.class} #{new} to bool field '#{field.name}'" unless new.is_a?(TrueClass) || new.is_a?(FalseClass)
      else 
        raise "Assigned object is not primitive and not a CheckedObject" unless new.is_a?(CheckedObject)
        raise "Inserting into the wrong model" unless  _graph_id.equal?(new._graph_id)
        unless _subtypeOf(new.schema_class, field.type)
          raise "Expected #{field.type.name} found #{new.schema_class.name}" 
        end
      end
    end

    old = @hash[field_name]
    return new if old == new
    @hash[field_name] = new
    notify_update(field, old, new)
    return new
  end
  
  def _subtypeOf(a, b)
    return true if a.name == b.name
    a.supers.detect do |sup|
      return _subtypeOf(sup, b)
    end
  end
  
  def method_missing(m, *args, &block)
    if m =~ /(.*)=/
      self[$1] = args[0]
    else
      return self[m.to_s]
    end
  end

  def to_s
    k = ClassKey(schema_class)
    "<#{schema_class.name} #{k && self[k.name]? self[k.name] + " " : ""}#{@_id}>"
  end

  def inspect
    to_s
  end
  
  def notify_update(field, old, new)
    inverse = field.inverse
    #puts "NOTIFY #{self}.#{field}/#{inverse} FROM '#{old}' to '#{new}'" if field.name=="types"
    return if inverse.nil?
    # remove the old one
    if old
      if !inverse.many
        old[inverse.name] = nil
      else
        old[inverse.name].delete(self)
      end
    end
    # add the new one
    if new
      if !inverse.many
        #puts "ASSIGN INVERSE #{new}[#{inverse.name}] = #{self}" if field.name=="types"
        new[inverse.name] = self
      else
        # don't do this now... it will get done during finalize
      end
    end
  end
  
  def finalize()
    UpdateInverses.new("INVERT").finalize(self)
    CheckRequired.new("REQUIRED").finalize(self)
  end  
end


class BaseManyField 
  include Enumerable
  
  def initialize(realself = nil, field = nil)
    @realself = realself
    @field = field
  end

  def nil?
    false
  end
  
  def empty?
    self.length == 0
  end

  def to_s
    "[" + map(&:to_s).join(", ") + "]"
  end

  def find_all(&block)
    return select(&block)
  end
end

# eg. "classes" field on Schema
class ManyIndexedField < BaseManyField
  
  def initialize(key, realself = nil, field = nil)
    super(realself, field)
    @hash = {}
    @key = key
  end
  
  def [](x)
    @hash[x]
  end
  
  def length
    @hash.length
  end
  
  def keys
    @hash.keys
  end
  
  def values
    @hash.values
  end
  
  def <<(v)
    k = v.send(@key)
    self[k] = v
  end

  # public main insertion function
  def []=(k, v)
    raise "Key cannot be nil for field #{v}" if !k
    
    # can't raise this error, for some reason
    # TODO:    raise "Item named '#{k}' already exists in '#{@field.name}'" if @hash[k]

    if @hash[k] != v
      @realself.notify_update(@field, @hash[k], v) if @realself
      @hash[k] = v
    end
    return v
  end
  
  def delete(v)
    k = v.send(@key)
    @hash.delete(k)
  end
  
  def clear()
    @hash.clear
  end
  
  def each(&block) 
    @hash.each_value &block
  end

  def +(other)
    r = ManyIndexedField.new(@key)
    self.each do |x| r << x end
    other.each do |x| r << x end
    #r._lock()
    return r
  end

  def reject
    r = ManyIndexedField.new(@key)
    each do |x| 
      r << x if not yield x 
    end
    #r._lock()
    return r
  end
  
  def select
    r = ManyIndexedField.new(@key)
    each do |x|
      r << x if yield x
    end
    #r._lock()
    return r
  end
  
  def flat_map
    r = ManyIndexedField.new(@key)
    each do |x|
      lst = yield x
      lst.each do |y|
        r << y
      end
    end
    return r
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

# eg. "classes" field on Schema
class ManyField < BaseManyField
  
  def initialize(realself = nil, field = nil)
    super(realself, field)
    @list = []
  end

  def [](x)
    @list[x]
  end
  
  def length
    @list.length
  end
  
  def nil?
    false
  end
  
  def last
    @list.last
  end
  
  def <<(v)
    @realself.notify_update(@field, nil, v) if @realself
    @list << v
  end

  def []=(i, v)
    @realself.notify_update(@field, @list[i], v) if @realself
    @list[i] = v
  end

  def delete(v)
    @list.delete(v)
  end

  def clear()
    @list.clear
  end
  
  def each(&block) 
    @list.each &block
  end

  def +(other)
    r = []
    self.each do |x| r << x end
    other.each do |x| r << x end
    return r
  end


  def flat_map(&block)
    r = ManyField.new
    each do |x|
      lst = yield x
      lst.each do |y|
        r << y
      end
    end
    return r
  end
  
  def keys
    Range.new(0, length, true)
  end
  
  def values
    @list
  end
  
  # sligthly nonstandard zip, includes all elements of this and other
  def outer_join(other)
    n = [length, other.length].max
    0.upto(n-1).each do |i|
      yield self[i], other[i], i
    end
  end
end  


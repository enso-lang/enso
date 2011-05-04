require 'cyclicmap'
require 'schema/finalize'

class Factory
  def initialize(schema)
    @schema = schema
  end

  def [](class_name)
    schema_class = @schema.classes[class_name.to_s]
    raise "Unknown class '#{class_name}'" unless schema_class
    obj = CheckedObject.new(schema_class, self)
    return obj
  end
  
  def method_missing(class_name, *args)
    obj = self[class_name.to_s]
    n = 0
    #puts "#{obj.schema_class.fields.keys}"
    obj.schema_class.fields.each_with_index do |field|
      next if field.computed
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
      next if field.computed
      if field.many
        # TODO: check for primitive many-valued???
        key = SchemaSchema.key(field.type)
        if key
          @hash[field.name] = ManyIndexedField.new(self, field, key)
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
    field = @schema_class.fields[field_name]; 
    if field_name[-1] == "?"
      return self.schema_class.name == field_name[0..-2]
    end
    raise "Accessing non-existant field '#{field_name}' of #{schema_class.name} in #{schema_class.schema.name}" unless field
    if field.computed
      r = self.instance_eval(field.computed.gsub(/@/, "self."))
      #puts "EVAL #{self}.#{field.name} = #{r}"
      return r
    else
      return @hash[field_name]
    end
  end

  def []=(field_name, new)
    #puts "Setting #{field_name} to #{new}"
    field = @schema_class.fields[field_name]
    raise "Assign to invalid field '#{field_name}' of #{@schema_class.name}" unless field
    raise "Can't set computed field '#{field_name}' of #{@schema_class.name}" if field.computed
    raise "Can't assign a many-valued field '#{field_name}' of #{@schema_class.name}" if field.many
    if new.nil?
      raise "Can't assign nil to required field '#{field_name}'" if !field.optional
    else
      case field.type.name
        when "str" then raise "Expected string found #{new.class} #{new}" unless new.is_a?(String)
        when "int" then raise "Expected int found #{new}" unless new.is_a?(Integer)
        when "bool" then raise "Expected bool found #{new}" unless new.is_a?(TrueClass) || new.is_a?(FalseClass)
        else 
          raise "Inserting into the wrong model" unless _graph_id.equal?(new._graph_id)
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
    return _subtypeOf(a.super, b) if a.super
  end
  
  def method_missing(m, *args, &block)
    if m =~ /(.*)=/
      self[$1] = args[0]
    else
      return self[m.to_s]
    end
  end

  def to_s
    k = SchemaSchema.key(schema_class)
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
  
  def initialize(realself, field)
    @realself = realself
    @field = field
  end

  def to_s
    "[" + map(&:to_s).join(", ") + "]"
  end

  def find_all(&block)
    return select(&block)
  end
  
  def reject(&block)
    r = ValueHash.new(@key.name)
    super.reject do |x| r << x end
    r._lock()
    return r
  end
  
  def select(&block)
    r = ValueHash.new(@key.name)
    super.select do |x| r << x end
    r._lock()
    return r
  end
end

# eg. "classes" field on Schema
class ManyIndexedField < BaseManyField
  
  def initialize(realself, field, key)
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
  
  def empty?
    @hash.empty?
  end

  def nil?
    false
  end
  
  def keys
    @hash.keys
  end
  
  def values
    @hash.values
  end
  
  def <<(v)
    k = v.send(@key.name)
    self[k] = v
  end

  # public main insertion function
  def []=(k, v)
    raise "Key cannot be nil for field #{v}" if !k
    
    # can't raise this error, for some reason
    # TODO:    raise "Item named '#{k}' already exists in '#{@field.name}'" if @hash[k]

    if @hash[k] != v
      @realself.notify_update(@field, @hash[k], v)
      @hash[k] = v
    end
    return v
  end
  
  def delete(v)
    k = v.send(@key.name)
    @hash.delete(k)
  end
  
  def each(&block) 
    @hash.each_value &block
  end

  def +(other)
    r = ValueHash.new(@key.name)
    self.each do |x| r << x end
    other.each do |x| r << x end
    r._lock()
    return r
  end
end  

# eg. "classes" field on Schema
class ManyField < BaseManyField
  
  def initialize(realself, field)
    super(realself, field)
    @list = []
  end

  def [](x)
    @list[x]
  end
  
  def length
    @list.length
  end
  
  def empty?
    @list.empty?
  end

  def nil?
    false
  end
  
  def last
    @list.last
  end
  
  def <<(v)
    @realself.notify_update(@field, nil, v) 
    @list << v
  end

  def []=(i, v)
    @realself.notify_update(@field, @list[i], v)
    @list[i] = v
  end

  def delete(v)
    @list.delete(v)
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
  
  # sligthly nonstandard zip, includes all elements of this and other
  def zip(other)
    extra = length.upto(other.length - 1).map do |x| nil end
    return (@list + extra).zip(other)
  end
end  



require 'core/system/library/schema'
require 'core/schema/code/finalize'

require 'ostruct'

class InternalLocation
  attr_reader :path, :offset, :length, :start_line, :start_column, :end_line, :end_column

  # (path, offset, length, start_line, start_column, end_line, end_column)
  def initialize(org)
    @path = org.path
    @offset = org.offset
    @length = org.length
    @start_line = org.start_line
    @start_column = org.start_column
    @end_line = org.end_line
    @end_column = org.end_column
  end

  def to_s
    "line #{start_line} column #{start_column} [#{length}] (#{File.basename(path)})"
  end

  def inspect
    "<#{path}: #{start_line}, #{start_column}, #{end_line}, #{end_column}, #{offset}, #{length}>"
  end

end

class Factory
  attr_reader :schema

  def initialize(schema)
    @schema = schema
  end

  # this is the core object constructor call
  # create a "virtual" object that conforms to schema class
  def [](class_name)
    method_missing(class_name)
  end

  # factory.Foo(args) creates an instance of Foo initialized with arguments  
  def method_missing(class_name, *args)
    schema_class = @schema.classes[class_name.to_s]
    raise "Unknown class '#{class_name}'" unless schema_class
    obj = CheckedObject.new(schema_class, self)
    n = 0
    #puts "#{obj.schema_class.fields.keys}"
    obj.schema_class.fields.each do |field|
      #puts "FIELD: #{field}"
      if n < args.length
        if !args[n].nil?
          if field.many
            col = obj[field.name]
            args[n].each do |x|
              col << x
            end
          else
            obj[field.name] = args[n]
          end
        end
      elsif !field.key && !field.optional && field.type.Primitive?
        case field.type.name
        when "str" then obj[field.name] = ""
        when "int" then obj[field.name] = 0
        when "bool" then obj[field.name] = false
        end
      end
      n += 1
    end
    raise "too many constructor arguments supplied for '#{class_name} (#{n} fields, #{args.length} args)" if n < args.length
    return obj
  end


  def delete_obj(obj)
    sc = obj.schema_class
    sc.fields.each do |fld|
      next if fld.type.Primitive?
      if fld.traversal then
        delete_obj(obj[fld.name])
      else
        if fld.inverse then
          if fld.inverse.many then
            obj[fld.name][fld.inverse.name].delete(obj)
          else
            obj[fld.name][fld.inverse.name] = nil
          end
        end
      end
    end
  end
end

module CheckedObjectMixin
  attr_reader :schema_class
  attr_reader :factory
  attr_reader :_id
  attr_accessor :_origin
  attr_reader :_origin_of
  
  def become!(obj)
    @factory = obj._graph_id
    @hash = obj._hash
    @_origin_of = obj._origin_of
    @_origin = obj._origin
    @schema_class = obj.schema_class
    @_id = obj._id
    @listeners = nil
  end


  # NB: JRuby --1.9 requires this: in it Object#type still exists
  # (although deprecated) so our method_missing does not fire.
  def type
    @hash['type']
  end

  def clone
    obj = @factory[schema_class.name]
    obj.become!(self)
    return obj
  end

  def semantic_equal?(obj)
    # NB: this depends on ManyFields performing
    # equality of their elements.
    obj._hash == @hash
  end

  def _graph_id
    @factory
  end

  def _hash
    @hash
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
      name = field_name[0..-2]
      return @schema_class.name == name || Subclass?(@schema_class, @schema_class.schema.types[name])
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

  def printStackTrace
   begin
      raise "nothing"
    rescue Exception => e
      puts e.backtrace
    end
  end
  
  def []=(field_name, new)
    if false # field_name=="name" && schema_class.name=="Rule" && new=="Schema"
      puts "Setting #{self}.#{field_name} to #{new}"
      printStackTrace 
    end
    #puts "Setting #{self}.#{field_name} to #{new}"
    field = @schema_class.fields[field_name]
    raise "Assign to invalid field '#{field_name}' of #{self}" unless field
    raise "Can't set computed field '#{field_name}' of #{self}" if field.computed
    raise "Can't assign a many-valued field #{self}.#{field_name} to #{new}" if field.many
    if new.nil?
      raise "Can't assign nil to required field '#{field_name}' of #{self}" if !field.optional
    else
      case field.type.name
      when "str" then raise "Attempting to assign #{new.class} #{new} to string field '#{field.name}'" unless new.is_a?(String)
      when "int" then raise "Attempting to assign #{new.class} #{new} to int field '#{field.name}'" unless new.is_a?(Integer)
      when "float" then raise "Attempting to assign #{new.class} #{new} to bool field '#{field.name}'" unless new.is_a?(Numeric)
      when "bool" then raise "Attempting to assign #{new.class} #{new} to bool field '#{field.name}'" unless new.is_a?(TrueClass) || new.is_a?(FalseClass)
      when "atom" then 
      else 
        raise "Assignment to #{self}.#{field_name} with incorrect type #{new.class} #{new}" unless new.is_a?(CheckedObject) 
        raise "Inserting into the wrong model" unless  _graph_id.equal?(new._graph_id)
        unless _subtypeOf(new.schema_class, field.type)
          puts "a: #{new.schema_class.supers}"
          puts "b: #{field.type}"
          raise "Error setting #{self}.#{field.name} to #{new.schema_class.name}" 
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
      _subtypeOf(sup, b)
    end
  end
  
  def method_missing(m, *args)
    if m =~ /(.*)=/
      self[$1] = args[0]
    else
      return self[m.to_s]
    end
  end

  def _clone
    r = CheckedObject.new(@schema_class, @factory)
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
  
  def to_s
    k = ClassKey(schema_class)
    "<#{schema_class.name} #{k && self[k.name]? self[k.name].inspect + " " : ""}#{@_id}>"
  end

  def inspect
    to_s
  end
  
  def add_listener(fieldname, listener)
    @listeners = {} if !@listeners
    ls = @listeners[fieldname]
    @listeners[fieldname] = ls = [] if !ls
	  ls.push(listener)
  end
  
  def dynamic_update
    @dyn = DynamicUpdateProxy.new(self) if !@dyn
    return @dyn
  end
  
  def notify_update(field, old, new)
    inverse = field.inverse
    #puts "NOTIFY #{self}.#{field}/#{inverse} FROM '#{old}' to '#{new}'" if field.name=="types"
    if @listeners
      @listeners[field.name].each do |listener|
      	listener.value = new
     end
    end
      
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

  def delete!
    _graph_id.delete_obj(self)
  end
  
  def finalize
    UpdateInverses.new("INVERT").finalize(self)
    CheckRequired.new("REQUIRED").finalize(self)
    return self
  end  
end

class CheckedObject 
  include CheckedObjectMixin

  @@_id = 0

  def initialize(schema_class, factory) #, many_index, many, int, str, b1, b2)
    @_id = @@_id += 1
    @hash = {}
    @_origin_of = OpenStruct.new
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
      @obj.add_listener(name, var)
      return var
    end
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

  def include?(x)
    !@hash[x.send(@key)].nil?
  end
  
  def [](x)
    @hash[x]
  end

  def ==(o)
    return false unless o.length == length
    each do |x|
      return false unless o.include?(x)
    end
    o.each do |x|
      return false unless include?(x)
    end
    return true
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
    raise "Key cannot be nil for field #{v}" if !k   
    if @hash[k] != v
      raise "Item named '#{k}' already exists in #{@realself}.#{@field.name}" if @hash[k]
      @realself.notify_update(@field, @hash[k], v) if @realself
      @hash[k] = v
    end
    return v
  end

  def []=(k, v)
    @realself.notify_update(@field, @hash[k], v) if @realself
    @hash[k] = v
  end

  def delete(v)
    k = v[@key]
    @hash.delete(k)
    # TODO: notify update???
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

  def include?(x)
    @list.include?(x)
  end
  
  def nil?
    false
  end
  
  def last
    @list.last
  end

  def ==(o)
    return false if o.length != length
    @list.each_with_index do |x, i|
      return false if x != o[i]
    end
    return true
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


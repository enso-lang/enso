
require 'core/system/utils/paths'
require 'core/schema/code/factory'
require 'json'
require 'enso'

=begin
Meta schema that is able to load any JSON file into memory as read-only pseudo-MObjects
An (not very) optional patchup phase makes it the schema class of itself (assuming it is a schema)

The only requirements are:
- root is a Schema
- Schema has field types 
=end

module Boot
  def self.load_path(path)
    load(System.readJSON(path)['model'])
  end
  
  def self.load(doc)
    ss0 = make_object(doc, nil)
    Copy(ManagedData.new(ss0), ss0)
  end

  class MObject < EnsoBaseObject
    attr_reader :_id
    @@seq_no = 0
    def initialize(data, root)
      @_id = (@@seq_no = @@seq_no + 1)
      @data = data
      @root = root || self
    end
    def schema_class
      #this assumes that the root is a schema and it has this thing called "types"
      res = @root.types[@data["class"]]
      self.define_singleton_method(:schema_class) { res }
      res
    end
    def _get(sym)
      res = if sym[-1] == "?"
        self.schema_class.name == sym.slice(0, sym.length-1)
      elsif @data.has_key?("#{sym}=")
        @data["#{sym}="]
      elsif @data.has_key?("#{sym}#")
        Boot.make_field(@data["#{sym}#"], @root, true)
      elsif @data.has_key?(sym.to_s)
        Boot.make_field(@data[sym.to_s], @root, false)
      else
        raise "Trying to deref nonexistent field #{sym} in #{@data.to_s.slice(0, 300)}"
      end
      self.define_singleton_method(sym) { res }
      res
    end
    def eql?(other)
      self._id==other._id
    end
    def to_s
      @name || @name = begin; "<#{@data['class']} #{self.name}>"
              rescue; "<#{@data['class']} #{self._id}>"; end
    end
  end

  class Schema < MObject
    def classes
      BootManyField.new(self.types.select{|t|t.Class?}, @root, true)
    end
    def primitives
      BootManyField.new(self.types.select{|t|t.Primitive?}, @root, true)
    end
  end
    
  class Class < MObject
    def all_fields
      BootManyField.new(self.supers.flat_map() {|s|s.all_fields} + defined_fields, @root, true)
    end
    def fields
      BootManyField.new(self.all_fields.select() {|f|!f.computed}, @root, true)
    end
  end

  def self.make_object(data, root)
    case data['class']
    when "Schema" 
      makeProxy(Schema.new(data, root))
    when "Class"  
      makeProxy(Class.new(data, root))
    else
      makeProxy(MObject.new(data, root))
    end
  end

  def self.make_field(data, root, keyed)
    if data.is_a?(Array)
      make_many(data, root, keyed)
    else
      get_object(data, root)
    end
  end
  
  def self.get_object(data, root)
    if !data
      nil
    elsif data.is_a?(String)
      Paths.parse(data).deref(root)
    else
      make_object(data, root)
    end
  end
  
  def self.make_many(data, root, keyed)
    arr = data.map {|a| get_object(a, root)}
    BootManyField.new(arr, root, keyed)
  end

  class BootManyField < Array
    def initialize(arr, root, keyed)
      arr.each {|obj| self.push obj}
      @root = root
      @keyed = keyed
    end
    def [](key)
      if @keyed
        self.find {|obj| obj.name == key}
      else
        self.at(key)
      end
    end
    def has_key?(key)
      self[key]
    end
    def join(other, &block)
      if @keyed
        other = other || {}
        ks = self.keys || other.keys
        ks.each {|k| block.call self[k], other[k]}
      else
        a = Array(self)
        b = Array(other)
        for i in 0..[a.length,b.length].max-1
          block.call a[i], b[i]
        end
      end
    end
    def keys
      if @keyed
        self.map {|o| o.name}
      else
        nil
      end
    end
  end
end




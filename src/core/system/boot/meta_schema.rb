
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
  class MObject < EnsoProxyObject
    attr_reader :_id
    attr_accessor :factory
    attr_accessor :_path
    attr_reader :file_path
    @@seq_no = 0
    def initialize(data, root)
      @_id = (@@seq_no = @@seq_no + 1)
      @data = data
      @root = root || self
      @factory = self
      @file_path = []
      @fields = {}
    end

    def schema_class
      @root.types[@data["class"]]
    end

    def [](sym)
      val = @fields[sym]
      if val
        val
      else
        @fields[sym] = if sym[-1] == "?"
          schema_class.name == sym.slice(0, sym.length-1)
        elsif @data.has_key?("#{sym}=")
          @data["#{sym}="]
        elsif @data.has_key?("#{sym}#")
          Boot.make_field(@data["#{sym}#"], @root, true)
        elsif @data.has_key?(sym.to_s)
          Boot.make_field(@data[sym.to_s], @root, false)
        else
          System.raise "Trying to deref nonexistent field #{sym} in #{@data.to_s.slice(0, 300)}"
        end
      end
    end
    
    def to_s
      @name || @name = begin; "<#{@data['class']} #{_id} #{name}>"
              rescue; "<#{@data['class']} #{_id}>"; end
    end
  end

  class Schema < MObject
    def classes
      BootManyField.new(types.select{|t|t.Class?}, @root, true)
    end
    def primitives
      BootManyField.new(types.select{|t|t.Primitive?}, @root, true)
    end
  end
    
  class Class < MObject
    def all_fields
      BootManyField.new(supers.flat_map() {|s|s.all_fields} + defined_fields, @root, true)
    end
    def fields
      BootManyField.new(all_fields.select() {|f|!f.computed}, @root, true)
    end
  end

  def self.load_path(path)
    load(System.readJSON(path))
  end
  
  def self.load(doc)
    ss0 = make_object(doc, nil)
    Copy(ManagedData.new(ss0), ss0)
  end

  def self.make_object(data, root)
    case data['class']
    when "Schema" 
      Schema.new(data, root)
    when "Class"  
      Class.new(data, root)
    else
      MObject.new(data, root)
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
      arr.each {|obj| push obj}
      @root = root
      @keyed = keyed
    end
    def [](key)
      if @keyed
        find {|obj| obj.name == key}
      else
        at(key)
      end
    end
    def has_key?(key)
      self[key]
    end
    def each_with_match(other, &block)
      if @keyed
        other = other || {}
        ks = keys || other.keys
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
        map {|o| o.name}
      else
        nil
      end
    end
  end
end




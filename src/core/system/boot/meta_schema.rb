
require 'core/schema/code/factory'
require 'core/schema/tools/union'
require 'enso'

#=begin
#Meta schema that is able to load any JSON file into memory as read-only pseudo-MObjects
#An (not very) optional patchup phase makes it the schema class of itself (assuming it is a schema)

#The only requirements are:
#- root is a Schema
#- Schema has field types 
#=end

module MetaSchema
  def self.load_path(path)
    json = Enso::System.readJSON(path)
    result = MetaSchema.load_doc(json['model'])
    
    result.factory.file_path[0] = json['source']
    result
  end
  
  def self.load_doc(doc)
    ss0 = MetaSchema.make_object(doc, nil)
    factory = Factory::make(ss0)
    ss0._complete(factory)
    # TODO: Fix Copy
    ss0 # Union::Copy(factory, ss0)
  end

  def self.make_object(data, root)
    if data != nil
      case data['class']
      when "Schema"
        raise "INVALID Schema root" if root != nil
        schema = Schema.new
        schema.setup(data, schema)
        schema
      when "Class"  
        klass = Class.new
        klass.setup(data, root)
        klass
      else
        obj = MObject.new
        obj.setup(data, root)
        obj
      end
    end
  end
  
  # this is a quick evaluator for simplifed path expressions found in json files
  def self.path_eval(str, obj)
    str.split(".").each do |part|
      n = part.index("[")
      if n > 0 && part.end_with?("]")
        field = part.slice(0, n)
        obj = obj[field]
        index = part.slice(n+1, part.size - n - 2)
        obj = obj[index]
      else
        obj = obj[part]
      end
    end
    obj
  end
  
  class MObject < Enso::EnsoProxyObject
    attr_reader :identity
    attr_accessor :factory
    attr_accessor :_path
    attr_reader :file_path
    @@seq_no = 0
    
    def _id()  @identity; end
    
    def setup(data, root)
      @identity = (@@seq_no = @@seq_no + 1)
      @factory = nil
      @file_path = []
      @root = root
      @data = data
      has_name = false
      data.each do |key, value|
        if key == "class"
        elsif key.end_with?("=")
          define_singleton_value(key.slice(0, key.size-1), value)
          if key == "name="
            has_name = true
            define_singleton_value("to_s", "<#{data['class']} #{value}>")
          end
        elsif value.is_a?(Array)
          keyed = key.end_with?("#")
          name = if keyed then key.slice(0, key.size-1) else key end
          if value.size == 0 || !(value[0].is_a?(String))
            _create_many(name, value.map {|a| MetaSchema.make_object(a, @root)}, keyed)
          end
        elsif !(value.is_a?(String))
          define_singleton_value(key, MetaSchema.make_object(value, @root))
        end
      end
      if !has_name
        define_singleton_value("to_s", "<#{data['class']}>")
      end
    end
    
    def _lookup(str, obj)
      str.split(".").each do |part|
        if (n = part.index("[")) && part.end_with("]")
          field = part.slice(0, n)
          obj = obj[field]
          index = part.slice(n+1, part.size - n - 2)
          obj = obj[index]
        else
          obj = obj[part]
        end
      end
      obj
    end
    
    def _complete(factory)
      self.factory = factory
      @data.each do |key, value|
        if key == "class"
          #puts("MetaCompleting #{value}")
          define_singleton_value("schema_class", @root.types[value])
		      define_singleton_method("is_a?") do |type| 
		        type == value
		      end
        elsif !key.end_with?("=") && value != nil
          if value.is_a?(Array) # why?
            keyed = key.end_with?("#")
            name = if keyed then key.slice(0, key.size-1) else key end
            if value.size > 0 && (value[0].is_a?(String))
              _create_many(name, value.map {|a| MetaSchema::path_eval(a, @root) }, keyed)
            else
              self[name].each do |obj|
                obj._complete(factory)
              end
            end
          elsif value.is_a?(String)
            define_singleton_value(key, MetaSchema::path_eval(value, @root))
          else
            self[key]._complete(factory)
          end
        end
      end
    end
    
    def _create_many(name, arr, keyed)
      define_singleton_value(name, BootManyField.new(arr, keyed))
    end
  end

  class Schema < MObject
    
    def classes
      BootManyField.new(types.select{|t|t.is_a?("Class")}, true)
    end
    def primitives
      BootManyField.new(types.select{|t|t.is_a?("Primitive")}, true)
    end
  end
    
  class Class < MObject
    def Class_P()
      true
    end
    def all_fields
      BootManyField.new((supers.flat_map() {|s|s.all_fields}).concat(defined_fields), true)
    end
    def fields
      BootManyField.new(all_fields.select() {|f|!f.computed}, true)
    end
    def key
      fields.find {|f| f.key}
    end
  end

  class BootManyField < Array
    include Enso::Enumerable
    
    def initialize(arr, keyed)
      super()
      arr.each {|obj| push obj}
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
        i = 0
        each do |a|
          block.call a, other && other[i] 
          i = i + 1
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




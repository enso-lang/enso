
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
    json = System.readJSON(path)
    result = load(json['model'])
    result.factory.file_path[0] = json['source']
    result
  end
  
  def self.load(doc)
    ss0 = make_object(doc, nil)
    ss0._complete
    Union::Copy(Factory::new(ss0), ss0)
  end

  def self.make_object(data, root)
    if data != nil
      case data['class']
      when "Schema"
        Schema.new(data, root)
      when "Class"  
        Class.new(data, root)
      else
        MObject.new(data, root)
      end
    end
  end
  
  def self.path_eval(str, obj)
    str.split(".").each do |part|
      if (n = part.index("[")) && part.slice(-1) == "]"
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
  


  class MObject < EnsoProxyObject
    attr_reader :_id
    attr_accessor :factory
    attr_accessor :_path
    attr_reader :file_path
    @@seq_no = 0
    
    def initialize(data, root)
      @_id = (@@seq_no = @@seq_no + 1)
      @factory = self
      @file_path = []
      @root = root || self
      @data = data
      has_name = false
      data.each do |key, value|
        if key == "class"
        elsif key[-1] == "="
          define_singleton_value(key.slice(0, key.size-1), value)
          if key == "name="
            has_name = true
            define_singleton_value("to_s", "<#{data['class']} #{_id} #{value}>")
          end
        elsif value.is_a?(Array)
          keyed = (key[-1] == "#")
          name = if keyed then key.slice(0, key.size-1) else key end
          if value.size == 0 || !(value[0].is_a?(String))
            _create_many(name, value.map {|a| MetaSchema.make_object(a, @root)}, keyed)
          end
        elsif !(value.is_a?(String))
          define_singleton_value(key, MetaSchema.make_object(value, @root))
        end
      end
      if !has_name
        define_singleton_value("to_s", "<#{data['class']} #{_id}>")
      end
    end
    
    def _lookup(str, obj)
      str.split(".").each do |part|
        if (n = part.index("[")) && part.slice(-1) == "]"
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
    
    def _complete
      @data.each do |key, value|
        if key == "class"
          define_singleton_value("schema_class", @root.types[value])
        elsif key[-1] != "=" && value != nil
          if value.is_a?(Array) # why?
            keyed = (key[-1] == "#")
            name = if keyed then key.slice(0, key.size-1) else key end
            if value.size > 0 && (value[0].is_a?(String))
              _create_many(name, value.map {|a| MetaSchema::path_eval(a, @root) }, keyed)
            else
              self[name].each do |obj|
                obj._complete
              end
            end
          elsif value.is_a?(String)
            define_singleton_value(key, MetaSchema::path_eval(value, @root))
          else
            self[key]._complete
          end
        end
      end
      @root.types.each do |cls|
        define_singleton_value("#{cls.name}?", @data['class'] == cls.name)
      end
    end
    
    def _create_many(name, arr, keyed)
      define_singleton_value(name, BootManyField.new(arr, @root, keyed))
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
      BootManyField.new((supers.flat_map() {|s|s.all_fields}).concat(defined_fields), @root, true)
    end
    def fields
      BootManyField.new(all_fields.select() {|f|!f.computed}, @root, true)
    end
    def key
      fields.find_first {|f| f.key}
    end
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




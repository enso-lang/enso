
require 'core/system/utils/paths'
require 'core/schema/code/factory'

=begin
Meta schema that is able to load any JSON file into memory as read-only pseudo-MObjects
An (not very) optional patchup phase makes it the schema class of itself (assuming it is a schema)

The only requirements are:
- root is a Schema
- Schema has field types 
=end

module Boot
  def self.load_path(path)
    load(JSON.load(File.new(path)))
  end
  
  def self.load(doc)
    ss0 = make_object(doc, nil)
    Copy(ManagedData::Factory.new(ss0), ss0)
  end

  class MObject
    attr_reader :_id
    begin; undef_method :lambda, :methods; rescue; end
    @@_id = 0
    def initialize(data, root)
      @_id = @@_id = @@_id+1
      @data = data
      @root = root || self
    end
    def schema_class
      #this assumes that the root is a schema and it has this thing called "types"
      res = @root.types[@data["class"]]
      define_singleton_method(:schema_class) { res }
      res
    end
    def [](sym)
      send(sym)
    end
    def type; method_missing :type; end  # HACK for JRuby to work, because it defines :type
    def method_missing(sym)
      #puts "GET #{sym} #{@data}"
      res = if sym[-1] == "?"
        schema_class.name == sym.slice(0, sym.length-1)
      elsif @data.key?("#{sym}=")
        @data["#{sym}="]
      elsif @data.key?("#{sym}#")
        Boot.make_field(@data["#{sym}#"], @root, true)
      elsif @data.key?(sym.to_s)
        Boot.make_field(@data[sym.to_s], @root, false)
      else
        raise "Trying to deref nonexistent field #{sym} in #{@data.to_s.slice(0, 300)}"
      end
      define_singleton_method(sym) { res }
      res
    end
    def eql?(other)
      hash == other.hash and _id==other._id
    end
    def to_s
      @name || @name = begin; "<#{@data['name']} #{name}>"
              rescue; "<#{@data['name']} #{_id}>"; end
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

  private

  @mobj_map={}
  def self.make_object(data, root)
    @mobj_map[data] || @mobj_map[data] = case data['class']
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
    if data.nil?
      nil
    elsif data.is_a?(String)
      Paths::Path.parse(data).deref(root)
    else
      Boot.make_object(data, root)
    end
  end
  
  def self.make_many(data, root, keyed)
    arr = data.map {|a| Boot.get_object(a, root)}
    BootManyField.new(arr, root, keyed)
  end

  class BootManyField < Array
    #A magical array that combines arrays, hashes and singletons 
    def initialize(arr, root, keyed)
      arr.each {|obj| self << obj}
      @root = root
      @keyed = keyed
    end
    def method_missing(sym)
      raise NoMethodError, "undefined method `#{sym}' for []:BootManyField"
    end
    def [](key)
      if @keyed
        find {|obj| obj.name == key}
      else
        at(key)
      end
    end
    def has_key?(key)
      not self[key].nil?
    end
    def join(other)
      if @keyed
        other = other || {}
        ks = keys | other.keys
        ks.each {|k| yield self[k], other[k]}
      else
        a = Array(self)
        b = Array(other)
        for i in 0..[a.length,b.length].max-1
          yield a[i], b[i]
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


if __FILE__ == $0 then
  require 'core/system/load/load'
  #require 'core/schema/tools/loadjson'
  require 'core/schema/tools/dumpjson'
  require 'core/diff/code/equals'
  
  mod = Loader.load('schema.schema')
  
  puts "Writing new metaschema"  
  ss_path = 'schema_schema2.json'
  File.open(ss_path, 'w+') do |f| 
    f.write(JSON.pretty_generate(ToJSON::to_json(mod, true)))
  end

  puts "Loading..."  
  ss = Boot.load_path(ss_path)
  File.delete(ss_path)
  
  puts "Testing"
  puts "Test1: Type=#{ss.types['Field'].defined_fields['type'].type.name}"
  puts "Test2: Class=#{ss.types['Field'].schema_class.name}"
  puts "Test2: Primitive=#{ss.types['int'].schema_class.name}"
  puts "Test3: 5=#{ss.types['Class'].defined_fields.length}"
  puts "Test4: " + (ss.types['Class'].defined_fields['defined_fields'].type==ss.types['Field'] ? "OK" : "Fail!")
  
  puts "Done loading new metaschema"
  
  realss = Loader.load('schema.schema')
  print "Equality test: "
  raise "Wrong result!" unless Equals.equals(realss, ss)
  puts "All OK!"
end

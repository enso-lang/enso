
require 'core/system/utils/paths'
require 'core/schema/code/factory'

=begin
Meta schema that is able to load any XML file into memory as read-only pseudo-MObjects
An (not very) optional patchup phase makes it the schema class of itself (assuming it is a schema)

The only requirements are:
- root is a Schema
- Schema has field types 
=end

module Boot
  def self.load_path(path)
    load(REXML::Document.new(File.read(path)))
  end
  
  def self.load(doc)
    ss0 = make_class(doc.root.elements.to_a[-1], nil)
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
      res = @root.types[@data.name]
      define_singleton_method(:schema_class) { res }
      res
    end
    def [](sym)
      send(sym)
    end
    def type; method_missing :type; end  # HACK for JRuby to work, because it defines :type
    def method_missing(sym)
      res = if sym[-1] == "?"
        schema_class.name == sym.slice(0, sym.length-1)
      elsif @data.attributes.include? sym.to_s
        MObject.coerce(@data.attributes[sym.to_s])
      elsif ! @data.elements[sym.to_s].nil?
        Boot.make_field(@data.elements[sym.to_s], @root)
      else
        # this is a strange hack, to avoid infinite recursion
        if f=schema_class.defined_fields[sym.to_s]
          MObject.default(f)
        elsif f=schema_class.all_fields[sym.to_s]
          MObject.default(f)
        else
          raise "Trying to deref nonexistent field #{sym} in #{@data.to_s.slice(0, 300)}"
        end
      end
      define_singleton_method(sym) { res }
      res
    end
    def eql?(other)
      hash == other.hash and _id==other._id
    end
    def self.coerce(value)
      #because we can't use schema class here, we have to be clever and guess
      if value == 'true'
        true
      elsif value == 'false'
        false
      elsif (begin; true if Integer(value); rescue; false; end)
        value.to_i
      elsif (begin; true if Float(value); rescue; false; end)
        value.to_f
      else
        value
      end
    end
    def self.default(field)
      if field.type.Primitive?  
        case field.type.name
        when 'str' then ''
        when 'int' then 0
        when 'bool' then false
        when 'real' then 0.0
        when 'datetime' then DateTime.now
        when 'atom' then nil
        else raise "Unknown primitive type: #{field.type.name}"
        end
      elsif field.many 
        BootManyField.new([], @root, keyed: true)
      elsif field.optional
        nil
      else
        nil  #raise "No value assigned to non-optional field #{self}.#{field.name} in XML"
      end
    end
    def to_ary; nil; end
    def to_s
      @name || 
      @name = begin; "<#{@data.name} #{name}>"
              rescue; "<#{@data.name} #{_id}>"; end
    end
  end

  class Schema < MObject
    def classes
      BootManyField.new(types.select{|t|t.Class?}, @root, keyed: true)
    end
    def primitives
      BootManyField.new(types.select{|t|t.Primitive?}, @root, keyed: true)
    end
  end
    
  class Class < MObject
    def all_fields
      BootManyField.new(supers.flat_map() {|s|s.all_fields} + defined_fields, @root, keyed: true)
    end
    def fields
      BootManyField.new(all_fields.select() {|f|!f.computed}, @root, keyed: true)
    end
  end

  private

  @mobj_map={}
  def self.make_class(data, root)
    return @mobj_map[data] if @mobj_map[data]
    @mobj_map[data] = if constants.map{|c|c.to_s}.include? data.name and (cl=Boot.const_get(data.name)).superclass==MObject
      #if Boot contains a subclass of MObject named the same as data.name then use that 
      cl.new(data, root)
    else #otherwise make a default MObject object
      MObject.new(data, root)
    end
    @mobj_map[data]
  end

  def self.make_field(data, root)
    if (arr = Boot.is_ref?(data))
      arr = arr.map {|a| deref(a, root)}
    else
      arr = data.elements.map {|a| Boot.make_class(a, root)}
    end
    if data.attributes['many']=='true'
      BootManyField.new(arr, root, keyed: (data.attributes['keyed']=='true'))
    else
      arr[0]
    end
  end

  def self.deref(ref, root)
    p = Paths::Path.parse(ref)
    p.deref(root)
  end

  def self.is_ref?(data)
    return nil unless data.elements.size==0
    v = data.get_text
    return nil if v.nil?
    v.empty? ? nil : v.to_s.strip.split(" ")
  end
  
  class BootManyField < Array
    #A magical array that combines arrays, hashes and singletons 
    def initialize(arr, root, attrs)
      arr.each {|obj|self << obj}
      @root = root
      @keyed = attrs[:keyed]
    end
    def method_missing(sym)
      raise NoMethodError, "undefined method `#{sym}' for []:BootManyField"
    end
    def [](key)
      if @keyed
        begin; find{|obj|obj.name==key}
        rescue; find{|obj|ObjectKey(obj)==key}; end
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
        begin; self.map {|o|o.name}
        rescue; self.map {|o|ObjectKey(o)}; end
      else
        nil
      end
    end
  end
end


if __FILE__ == $0 then
  require 'core/system/load/load'
  require 'core/schema/tools/loadxml'
  require 'core/schema/tools/dumpxml'
  require 'rexml/document'
  include REXML
  
  mod = Loader.load('schema.schema')
  pp = REXML::Formatters::Pretty.new
  ss_path = 'schema_schema2.xml'
  File.open(ss_path, 'w+') {|f| pp.write(ToXML::to_doc(mod), f)}
  
  ss = Boot.load_path(ss_path)
  File.delete(ss_path)
  
  puts "Test1: " + (ss.types['Field'].defined_fields['type'].type.name=='Type' ? "OK" : "Fail!")
  puts "Test2: " + (ss.types['Class'].defined_fields.length==5 ? "OK" : "Fail!")
  puts "Test3: " + (ss.types['Class'].defined_fields['defined_fields'].type==ss.types['Field'] ? "OK" : "Fail!")
  
  puts "Done loading metaschema"
  
  realss = Loader.load('schema.schema')
  print "Equality test: "
  raise "Wrong result!" unless Equals.equals(realss, ss)
  puts "All OK!"
end

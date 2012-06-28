
require 'core/system/utils/paths'

=begin
Meta schema that is able to load any XML file into memory as read-only pseudo-MObjects
An (not very) optional patchup phase makes it the schema class of itself (assuming it is a schema)

The only requirements are:
- root is a Schema
- Schema has field types 
=end

module Boot0
  def self.load(doc)
    make_class(doc.root, nil)
  end
  
  class MObject; end

  class Schema < MObject
    def classes
      BootField.new(types.select{|t|t.Class?}, self, "classes", @root, :many=>true, :keyed=>true)
    end
    def primitives
      BootField.new(types.select{|t|t.Primitive?}, self, "primitives", @root, :many=>true, :keyed=>true)
    end
  end
    
  class Class < MObject
    def all_fields
      BootField.new(supers.flat_map() {|s|s.all_fields} + defined_fields, self, "all_fields", @root, :many=>true, :keyed=>true)
    end
    def fields
      BootField.new(all_fields.select() {|f|!f.computed}, self, "fields", @root, :many=>true, :keyed=>true)
    end
  end

  private

  @mobj_map={}
  def self.make_class(this, root)
    return @mobj_map[this] if @mobj_map[this]
    @mobj_map[this] = if constants.map{|c|c.to_s}.include? this.name and (cl=Boot0.const_get(this.name)).superclass==MObject
      #if Boot0 contains a subclass of MObject named the same as this.name then use that 
      cl.new(this, root)
    else #otherwise make a default MObject object
      MObject.new(this, root)
    end
    @mobj_map[this]
  end

  def self.make_field(this, owner, field, root)
    if this.attributes['many']!='true' && false
      res = if (arr = Boot0.is_ref?(this))
        deref(arr[0], root)
      else
        make_class(this, root)
      end
      res
    else
      if (arr = Boot0.is_ref?(this))
        arr = arr.split(" ").map {|a|deref(a, root)}
      else
        arr = this.elements.map {|a|Boot0.make_class(a, root)}
      end
      BootField.new(arr, owner, field, root, :many=>(this.attributes['many']=='true'), :keyed=>(this.attributes['keyed']=='true'))
    end
  end

  def self.deref(ref, root)
    p = Paths::Path.parse(ref)
    p.deref(root)
  end

  def self.is_ref?(elem)
    return nil unless elem.elements.size==0
    v = elem.get_text
    return nil if v.nil?
    v.empty? ? nil : v.to_s.strip
  end

  class MObject
    attr_reader :this, :_id
    undef_method :lambda
    @@_id = 0
    def initialize(this, root)
      @_id = @@_id = @@_id+1
      @this = this
      @root = root || self
    end
    def schema_class
      #this assumes that the root is a schema and it has this thing called "types"
      res = @root.types[@this.name]
      define_singleton_method(:schema_class) { res }
      res
    end
    def [](sym)
      send(sym)
    end
    def method_missing(sym)
      res = if sym =~ /^([A-Z].*)\?$/
        schema_class.name == $1
      elsif @this.attributes.include? sym.to_s
        MObject.coerce(@this.attributes[sym.to_s])
      elsif ! @this.elements["#{sym}"].nil?
        Boot0.make_field(@this.elements["#{sym}"], self, sym.to_s, @root)
      else
        if f=schema_class.defined_fields[sym.to_s]
          MObject.default(f)
        elsif f=schema_class.all_fields[sym.to_s]
          MObject.default(f)
        else
          raise "Trying to deref nonexistent field #{sym} in #{@this.to_s[0..300]}"
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
      if ['true', 'false'].include? value
        value == 'true' ? true : false
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
        BootField.new([], self, field.name, @root, :many=>true, :keyed=>true)
      elsif field.optional
        nil
      else
        nil  #raise "No value assigned to non-optional field #{self}.#{field.name} in XML"
      end
    end
    def to_ary; nil; end
    def to_s
      begin; "<#{@this.name} #{name}>"
      rescue; "<#{@this.name} #{_id}>"; end
    end
  end
  
  class BootField < Array
    attr_reader :owner
    #A magical array that combines arrays, hashes and singletons 
    def initialize(arr, owner, field, root, attrs)
      arr.each {|obj|self << obj}
      @owner = owner
      @field = field
      @root = root
      @many = attrs[:many]
      @keyed = attrs[:keyed]
    end
    def method_missing(sym)
      at(0).send(sym) unless @many
    end
    def [](key)
      if !@many 
        at(0).send(key)
      else
        if @keyed
          begin; find{|obj|obj.name==key}
          rescue; find{|obj|ObjectKey(obj)==key}; end
        else
          at(key)
        end
      end
    end
    def eql?(other)
      !@many ? at(0).eql?(other) : super
    end
    def hash
      !@many ? at(0).hash : super
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
      if @many
        if @keyed
          begin; self.map {|o|o.name}
          rescue; self.map {|o|ObjectKey(o)}; end
        else
          nil
        end
      else
        method_missing("keys")
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

ss = Boot0.load(Document.new(File.read(ss_path)))
File.delete(ss_path)

puts "Test1: " + (ss.types['Schema'].schema.eql?(ss.types.owner) ? "OK" : "Fail!")
puts "Test2: " + (ss.types['Field'].defined_fields['type'].type.to_s=="[<Class Type>]" ? "OK" : "Fail!")
puts "Test3: " + (ss.types['Class'].defined_fields['defined_fields'].to_s=="<Field defined_fields>" ? "OK" : "Fail!")

puts "Done loading metaschema"

fact = ManagedData::Factory.new(ss)

puts "Done making metafactory"

t1 = Time.now
ss1 = Copy(fact, ss)
puts "Took #{Time.now-t1}s to clone with metaschema"

puts "Done copying"

realss = Loader.load('schema.schema')
raise "Wrong result!" unless Equals.equals(realss, ss1)
puts "All OK!"

end

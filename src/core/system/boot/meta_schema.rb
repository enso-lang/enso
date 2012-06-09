
require 'core/system/utils/paths'

=begin
Idea (getting rid of the fake checked objects)
 
- instantiate Boot::Schema initialized with schema_schema.xml: ssboot
- ss = loadxml(schema_schema.xml, ManagedData::Factory.new(ssboot))
- patch schema_pointers

Grammar_schema.xml and instance_schema.xml can be loaded using ss.  No
schema pointer patching is needed here. After that we can load
grammar_grammar.xml. And we can parse the real stuff.
=end

module Boot
  # these classes should be behaviorally equivalent to the schema.schema
  # that is loaded from xml and grammars. They are only used to load
  # from schema_schema.xml.

  class Mock
    attr_accessor :schema_class
    # needed for path resolving
    def [](name)
      send(name)
    end
  end

  class Many < Hash
    # hash behaving as a keyed many field
    def each(&block)
      each_value(&block)
    end
  end

  class Schema < Mock
    attr_reader :classes, :types, :primitives
    def initialize(this)
      @this = this

      @classes = Many.new
      @this.elements.each('types/Class') do |elt|
        c = Class.new(elt, self)
        @classes[c.name] = c
      end

      @primitives = Many.new
      @this.elements.each('types/Primitive') do |elt|
        p = Primitive.new(elt, self)
        @primitives[p.name] = p
      end
      @types = @classes.merge(@primitives)

      @classes.each do |v|
        v.schema_class = @classes['Class']
        v.defined_fields.each do |f|
          f.schema_class = @classes['Field']
        end
      end
      @schema_class = @classes['Schema']
    end
  end

  class Type < Mock
    attr_reader :name, :schema

    def initialize(this, schema)
      @this = this
      @schema = schema
      @name = this.attributes['name']
    end

    def Primitive?; false end
    def Class?; false end
  end

  class Primitive < Type
    def Primitive?; true end
  end

  class Class < Type
    attr_reader :supers, :subclasses, :defined_fields

    def initialize(this, schema)
      super(this, schema)
      @defined_fields = Many.new
      @this.elements.each('defined_fields/*') do |elt|
        f = Field.new(elt, self)
        @defined_fields[f.name] = f
      end
    end

    def Class?; true end

    def supers
      m = Many.new
      elt = @this.elements['supers']
      if elt then
        ps = elt.get_text.value.strip.split
        ps.each do |p|
          c = Paths::Path.parse(p).deref(schema)
          m[c.name] = c
        end
      end
      return m
    end

    def all_fields
      m = Many.new
      supers.each do |c|
        c.all_fields.each do |f|
          m[f.name] = f
        end
      end
      m.merge(defined_fields)
    end

    def fields
      m = Many.new
      all_fields.each do |f|
        if !f.computed then
          m[f.name] = f
        end
      end
      m
    end
  end

  class Field < Mock
    attr_reader :owner

    def initialize(this, owner)
      @this = this
      @owner = owner
    end

    def type
      p = Paths::Path.parse(@this.elements['type'].get_text.value.strip)
      p.deref(owner.schema)
    end

    def inverse
      elt = @this.elements['inverse']
      return unless elt
      p = Paths::Path.parse(elt.get_text.value.strip)
      p.deref(owner.schema)
    end
    
    def computed
      c = @this.elements['computed/ECode']
      return nil if c.nil?
      ECode.new(c, self) 
    end

    def method_missing(sym)
      @this.attributes[sym.to_s]
    end
  end
  
  #this is used to make bootstrap boot properly 
  #with computed fields but not full expression support
  class ECode < Mock
    def initialize(this, field)
      @this = this
      @field = field
    end
    def ECode?; true end

    def method_missing(sym)
      @this.attributes[sym.to_s]
    end
  end

end


if __FILE__ == $0 then
  require 'rexml/document'
  require 'core/schema/tools/print'
  require 'core/schema/tools/loadxml'

  include REXML
  doc = Document.new(File.read('core/system/boot/schema_schema.xml'))

  ss = Boot::Schema.new(doc.root)
  ss2 = FromXML.load(ss, doc)

  puts "ss2: #{ss2.to_s}"
  puts "ss2.schema_class: #{ss2.schema_class.to_s}"

  Boot::patch_schema_pointers(ss2)
  puts "After patch"
  puts "ss2: #{ss2}"
  $stdout.flush
  puts "ss2.schema_class: #{ss2.schema_class.to_s}"

  #Print.print(ss2)
  
  ss3 = FromXML.load(ss2, doc)
  puts ss3.to_s
  puts ss3.schema_class.to_s
  puts ss3.schema_class.schema_class.to_s

  Print.print(ss3)
end

require 'cyclicmap'
require 'schema/factory'

# problem
# cyclic visiting on schema: stops to early, because it may find the the same class many times
# cyclic visiting on mode: stops to early,  because  the same primitive value may occur many times


class Conformance < CyclicCollectOnBoth
  attr_reader :errors

  def initialize()
    super()
    @errors = []
  end

  def Primitive(this, obj)
    ok = case this.name
        when "str"  then obj.is_a?(String)
        when "int"  then obj.is_a?(Integer)
        when "bool"  then obj.is_a?(TrueClass) || obj.is_a?(FalseClass)
        end
    unless ok
      @errors << "Type mismatch: expected #{this.name}, got #{obj}"
    end
  end

  def Klass(this, obj)
    puts "KLASS: Checking #{obj} against #{this.name}"
    if !obj.is_a?(CheckedObject) && !obj.is_a?(SchemaModel)
      @errors << "Expected class type, not primitive '#{obj.class}'"
    elsif !subtypeOf(obj.schema_class, this) then
      @errors << "Invalid class: expected #{this.name}, got #{obj.schema_class.name}"
    else
      this.fields.each do |f|
        recurse(f, obj)
      end
    end
  end
  
  def subtypeOf(a, b)
    return true if a.name == b.name
    return subtypeOf(a.super, b) if a.super
  end

  def Field(field, obj)
    val = obj[field.name]
    puts "FIELD: #{field.name}, #{val}"

    if field.optional
      return if !field.many && val.nil?
    else
      if !field.many ? val.nil? : val.empty?
        @errors << "Field #{field.name} is required" 
      end
    end
    
    # check the field values    
    _each(obj, field) do |val|
      recurse(field.type, val)
    end
   
    puts "THIS.Type: #{field.type.name}"
  end  

  def _each(obj, field)
    if !field.many
      yield obj[field.name]
    else
      obj[field.name].each do |x|
        yield x
      end
    end
  end
end

if __FILE__ == $0 then
  require 'schema/schemaschema'
  
  ss = SchemaSchema.schema
  # if you want to print something out, see example at end of print.rb 
  puts "Checking #{ss.name}"

  check = Conformance.new
  check.recurse(ss.classes["Schema"], ss)
  check.errors.each do |x|
    puts x
  end
end


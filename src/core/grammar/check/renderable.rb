

require 'core/grammar/check/fieldsof'
require 'core/grammar/check/typeof'
require 'core/system/library/schema'

class Renderable
  def initialize(schema, root)
    @schema = schema
    @root = root
    @type_of = TypeOf.new(schema, root)
    @fields_of = FieldsOf.new(schema, root, @type_of)
    @visited_classes = []
    @memo = {}
  end

  def error(msg)
    puts "ERROR: #{msg}"
  end

  # NB: this the reverse logic of the check_fields
  # in Buildable.
  def check_fields(klass, fs)
    fields = klass.fields
    puts "CHECKFIELDS #{klass.name}: \n - inferred: #{fs}\n - needed: #{klass.fields}"
    fields.each do |fld|
      next if fld.inverse
      #puts "Checking #{fld} against #{fs[fld.name]}"
      if fs[fld.name].nil? then
        error("Field #{fld.name} in #{klass.name} cannot be rendered")
      elsif fld.type.Class? && fs[fld.name].type.primitive? && 
          !Schema::subclass?(fld.type, fs[fld.name].type.klass) then
        error("Type #{fld.type} not subtype of inferred #{fs[fld.name].type} in #{fld.name} of  #{klass.name}")
      elsif fld.type.Primitive? && fs[fld.name].type.primitive? && 
          fld.type != fs[fld.name].type.primitive && 
          fs[fld.name].type.primitive.name != 'atom' then
        error("Type #{fld.type} not compatible to inferred #{fs[fld.name].type} of #{fld.name} in #{klass.name}")
      elsif !(mult_of(fld) <= fs[fld.name].mult) then
        error("Multiplicity #{mult_of(fld)} not sub inferred #{fs[fld.name].mult} of #{fld.name} in #{klass.name}")
      end
    end
  end

  def mult_of(field)
    if field.optional then
      field.many ? Multiplicity::ZERO_OR_MORE : Multiplicity::ZERO_OR_ONE
    elsif field.many
      Multiplicity::ONE_OR_MORE
    else
      Multiplicity::ONE
    end
  end

  def check_grammar(grammar)
    check(grammar.start, @root, nil, nil)
  end

  def check(this, klass, field, owner)
    if respond_to?(this.schema_class.name) then
      send(this.schema_class.name, this, klass, field, owner)
    else
      false
    end
  end

  def Sequence(this, klass, field, owner)
    if this.elements.length == 0 then
      false
    elsif this.elements.length == 1 then
      check(this.elements.first, klass, field, owner)
    else
      x = check(this.elements[0], klass, field, owner)
      1.upto(this.elements.length - 1) do |i|
        x ||= check(this.elements[i], klass, field, owner)
      end
      return x
    end
  end

  def Alt(this, klass, field, owner)
    x = check(this.alts[0], klass, field, owner)
    1.upto(this.alts.length - 1) do |i|
      x ||= check(this.alts[i], klass, field, owner)
    end
    return x
  end


  def Create(this, klass, field, owner)
    fs = @fields_of.fields_of(this.arg, klass)
    check_fields(klass, fs)
    ok = false
    klass.fields.each do |fld|
      if fld.type.Class? then
        ok_field = check(this.arg, fld.type, fld, klass)
        if !ok_field then
          #error("Can't render #{fld.name} of class #{klass.name}")
        end
        ok ||= ok_field
      end
    end
    return ok
  end

  def Field(this, klass, field, owner)
    if this.name == field.name then
      check(this.arg, klass, nil, owner)
    else
      false
    end
  end

  def Rule(this, klass, field, owner)
    check(this.arg, klass, field, owner)
  end

  def Call(this, klass, field, owner)
    if @memo[this]
      return @memo[this]
    end

    @memo[this] = false

    x = check(this.rule, klass, field, owner)
    while x != @memo[this]
      @memo[this] = x
      x = check(this.rule, klass, field, owner)
    end
    return x
  end

  def Ref(this, klass, field, owner)
    cls = DerefSchema.new(@schema, @root).deref(this.path, owner)
    return cls == klass
  end

  def Regular(this, klass, field, owner)
    check(this.arg, klass, field, owner)
  end

end


if __FILE__ == $0 then
  if !ARGV[0] || !ARGV[1] || !ARGV[2] then
    puts "use renderable.rb <name>.grammar <name>.schema <rootclass>"
    exit!(1)
  end


  require 'core/system/load/load'
  require 'pp'

  g = Load::load(ARGV[0])
  s = Load::load(ARGV[1])
  start = ARGV[2]

  root_class = s.classes[start]

  check = Renderable.new(s, root_class)
  check.check_grammar(g)
end

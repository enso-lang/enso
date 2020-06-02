
require 'core/grammar/check/fieldsof'
require 'core/grammar/check/typeof'
require 'core/system/library/schema'

class Buildable
  def initialize(schema, root)
    @schema = schema
    @root = root
    @type_of = TypeOf.new(schema, root)
    @fields_of = FieldsOf.new(schema, root, @type_of)
  end

  def error(msg)
    puts "ERROR: #{msg}"
  end

  def check_fields(fs, klass, create)
    fields = klass.fields
    fs.each do |fn, tm|
      puts "Checking #{fn}: #{tm} against #{fields[fn]}"
      if fields[fn].nil? then
        error("No field #{fn} in #{klass.name}")
      elsif tm.type.klass? && !Schema::subclass?(tm.type.klass, fields[fn].type) then
        error("Type #{tm.type.klass} not subtype of #{fields[fn].type} of #{fn} in #{klass.name}")
      elsif tm.type.primitive? && tm.type.primitive != fields[fn].type &&
          fields[fn].type.name != 'atom' then
        error("Type #{tm.type.primitive} not compatible to  #{fields[fn].type} of #{fn} in #{klass.name}")
      elsif !(tm.mult <= mult_of(fields[fn])) then
        error("Multiplicity #{tm.mult} not sub #{mult_of(fields[fn])} of #{fn} in #{klass.name}")
      end
    end
  end

  def check_absent_fields(fs, klass, create)
    # NB: this does not deal with inverses...
    klass.fields.each do |f|
      if fs[f.name].nil? && !f.optional then
        error("Required field #{f.name} is not assigned at #{create}")
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
    grammar.rules.each do |rule|
      check(rule)
    end
  end

  def check(this)
    if respond_to?(this.schema_class.name) then
      send(this.schema_class.name, this)
    end
  end

  def Sequence(this)
    this.elements.each do |x|
      check(x)
    end
  end

  def Alt(this)
    this.alts.each do |x|
      check(x)
    end
  end

  def Regular(this)
    check(this.arg)
  end

  def Field(this)
    check(this.arg)
  end

  def Rule(this)
    check(this.arg) if this.arg
  end

  def Create(this)
    klass = @schema.classes[this.name]
    if klass.nil?
      error("No class for create #{this}") 
    else
      fs = @fields_of.fields_of(this.arg, klass)
      check_fields(fs, klass, this)
      check_absent_fields(fs, klass, this)
    end
    check(this.arg)
  end

end

if __FILE__ == $0 then
  if !ARGV[0] || !ARGV[1] || !ARGV[2] then
    puts "use buildable.rb <name>.grammar <name>.schema <rootclass>"
    exit!(1)
  end


  require 'core/system/load/load'
  require 'pp'

  g = Load::load(ARGV[0])
  s = Load::load(ARGV[1])
  start = ARGV[2]

  root_class = s.classes[start]

  check = Buildable.new(s, root_class)
  check.check_grammar(g)
end

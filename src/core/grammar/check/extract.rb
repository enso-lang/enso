
require 'core/system/load/load'
require 'core/schema/code/factory'
require 'core/grammar/check/deref-type'

# extract a minimally viable schema from a grammar.

class ExtractSchema

  def initialize
    @fact = ManagedData::Factory.new(Loader.load('schema.schema'))
  end

  def extract(grammar)
    @schema = @fact.Schema
    @root_class = nil
    @lub_of = {}
    @anon_counter = 0
    begin
      @memo = {}    
      @change = false
      eval(grammar.start, nil, nil, false)
    end while @change
    @schema
  end

  def eval(this, owner, fld, in_field)
    #puts "EVALING: #{this.schema_class.name} with #{owner} and #{fld}"
    send(this.schema_class.name, this, owner, fld, in_field)
  end

  def Sequence(this, owner, fld, in_field)
    this.elements.each do |elt|
      eval(elt, owner, fld, false)
    end
  end

  def Alt(this, owner, fld, in_field)
    this.alts.each do |alt|
      eval(alt, owner, fld, in_field)
    end
  end

  def Rule(this, owner, fld, in_field)
    # TODO: move to schema
    return if this.arg.nil? # abstract
    eval(this.arg, owner, fld, in_field)
  end

  def Call(this, owner, fld, in_field)
    return if @memo[[this,owner,fld]]
    @memo[[this,owner,fld]] = true
    eval(this.rule, owner, fld, in_field)
  end

  def Create(this, owner, fld, _)
    unless @schema.types[this.name] then
      @schema.types << @fact.Class(this.name)
      puts "schema.types: #{@schema.types}"
      @change = true
    end
    cls = @schema.types[this.name]
    @root_class ||= cls

    if fld then
      new_type = type_lub(fld.type, cls)
      if new_type != fld.type then
        fld.type = new_type
        # NON-TERMINATION!!!
        # @change = true
      end
      # THIS IS A BIG ASSUMPTION
      # (but needed now, for rendering)
      fld.traversal = true
    end

    eval(this.arg, cls, nil, false)
  end

  def Field(this, owner, _, _)
    unless owner.defined_fields[this.name] then
      owner.defined_fields << @fact.Field(this.name)
      @change = true
    end
    eval(this.arg, owner, owner.defined_fields[this.name], true)
  end

  def Lit(this, owner, fld, in_field)
    return unless in_field
    new_type = type_lub(fld.type, primitive('str'))
    if new_type != fld.type then
      fld.type = new_type
      @change = true
    end
  end

  def Value(this, owner, fld, in_field)
    p = this.kind == 'sym' ? 'str' : this.kind
    new_type = type_lub(fld.type, primitive(p))
    if new_type != fld.type then
      fld.type = new_type
      @change = true
    end
  end

  def Ref(this, owner, fld, in_field)
    cls = DerefType.deref(@schema, @root_class, owner, this.path)
    return if cls.nil?
    new_type = type_lub(fld.type, cls) 
    if new_type != fld.type then
      fld.type = new_type
      @change = true
    end
  end

  def Regular(this, owner, fld, in_field)
    # multiplicity is done in separate phase
    eval(this.arg, owner, fld, in_field)
  end

  def Code(this, owner, _, _)
    # TODO: parse this.code
  end

  private

  def primitive(name)
    unless @schema.types[name] then
      @schema.types << @fact.Primitive(name)
      @change = true
    end
    @schema.types[name] 
  end

  def class_lub(t1, t2)
    return t1 if t1 == t2
    return t2 if Subclass?(t1, t2)
    return t1 if Subclass?(t2, t1)
    t1.supers.each do |sup1|
      t2.supers.each do |sup2|
        x = class_lub(sup1, sup2)
        return x if x
      end
    end
    return nil
  end

  def type_lub(t1, t2)
    return t2 if t1.nil?
    return t1 if t1 == t2
    if t1.Primitive? && t2.Primitive? then
      primitive('atom')
    elsif t1.Class? && t2.Class? then
      x = class_lub(t1, t2)
      return x if x
      @anon_counter += 1
      anon_class = @fact.Class("C_#{@anon_counter}")
      @schema.types << anon_class
      t1.supers << anon_class
      t2.supers << anon_class
      @change = true
      return anon_class
    else
      raise "Cannot lub primitive and class types #{t1.name} and #{t2.name}"
    end
  end

end


if __FILE__ == $0 then
  require 'core/grammar/render/layout'
  require 'core/schema/tools/print'
  grammar = ARGV[0]
  xg = Loader.load(grammar)
  xs = ExtractSchema.new.extract(xg)
  Print.print(xs)
  sg = Loader.load('schema-base.grammar')
  File.open('bla.dot', 'w') do |f|
    f.puts("digraph bla {")
    xs.classes.each do |c|
      c.supers.each do |s|
        f.puts("#{c.name} -> #{s.name}")
      end
    end
    f.puts("}")
  end
  DisplayFormat.print(sg, xs)
end



require 'core/grammar/check/typeof'

class FS
  attr_reader :tbl

  def initialize(tbl = {})
    @tbl = tbl
  end

  def ==(o)
    tbl == o.tbl
  end

  def eql?(o)
    self == o
  end

  def hashcode
    tbl.hashcode
  end

  def to_s
    tbl.to_s
  end

  def +(o)
    merge(o, :+)
  end

  def *(o)
    merge(o, :*)
  end

  def opt(klass)
    regularize(klass, :opt)
  end

  def plus(klass)
    regularize(klass, :plus)
  end

  def star(klass)
    regularize(klass, :star)
  end
  
  def regularize(klass, op)
    new_fields = {}
    tbl[klass].each do |name, tm|
      new_fields[name] = TM.new(tm.type, tm.mult.send(op))
    end
    new_tbl = tbl.clone
    new_tbl[klass] = new_fields
    FS.new(new_tbl)
  end
  
  private
  def merge(o, op)
    #puts "MERGING #{op} \n - #{self}\n - #{o}"
    shared_classes = tbl.keys & o.tbl.keys
    new_tbl = {}
    shared_classes.each do |kls|
      new_tbl[kls] = {}
      shared = tbl[kls].keys & o.tbl[kls].keys
      new_fields = {}
      bottom = TM.new(GrammarTypes::VOID, Multiplicity::ZERO)
      shared.each do |k|
        new_fields[k] = tbl[kls][k].send(op, o.tbl[kls][k])
      end
      (tbl[kls].keys - o.tbl[kls].keys).each do |k|
        new_fields[k] = tbl[kls][k].send(op, bottom)
      end    
      (o.tbl[kls].keys - tbl[kls].keys).each do |k|
        new_fields[k] = o.tbl[kls][k].send(op, bottom)
      end
      new_tbl[kls] = new_fields
    end
    (tbl.keys - o.tbl.keys).each do |kls|
      new_tbl[kls] = tbl[kls]
    end
    (o.tbl.keys - tbl.keys).each do |kls|
      new_tbl[kls] = o.tbl[kls]
    end
    r = FS.new(new_tbl)
    #puts "INTO ---> #{r}"
    r
  end

  
end

class FieldsOf
  BOT = FS.new

  def initialize(schema)
    @schema = schema
    @typeof = TypeOf.new(schema)
    @memo = {}
  end


  def fields_of(obj, klass)
    #puts "SENDING to: #{obj.schema_class.name}"
    if respond_to?(obj.schema_class.name) then
      send(obj.schema_class.name, obj, klass)
    else
      BOT
    end
  end

  def Sequence(this, klass)
    if this.elements.length == 0 then
      BOT
    elsif this.elements.length == 1 then
      fields_of(this.elements.first, klass)
    else
      x = fields_of(this.elements[0], klass)
      1.upto(this.elements.length - 1) do |i|
        x *= fields_of(this.elements[i], klass)
      end
      return x
    end
  end

  def Call(this, klass)
    if @memo[this.rule.name]
      return @memo[this.rule.name]
    end

    @memo[this.rule.name] = BOT
    x = fields_of(this.rule, klass)
    while x != @memo[this.rule.name]
      @memo[this.rule.name] = x
      x = fields_of(this.rule, klass)
    end
    return x
  end

  def Rule(this, klass)
    fields_of(this.arg, klass)
  end

  def Alt(this, klass)
    x = fields_of(this.alts[0], klass)
    1.upto(this.alts.length - 1) do |i|
      x += fields_of(this.alts[i], klass)
    end
    return x
  end

  # todo: Code

  def Code(this, klass)
    fs = {}
    yield_objects(this.expr) do |x|
      next if x.nil?
      if x.EVar? then
        # buggy, need to really use klass
        fs[x.name] = TM.new(GrammarTypes::Primitive.new(@schema.types['bool']), 
                            Multiplicity::ONE)
        # GrammarTypes::Primitive.new(klass.fields[x.name].type)
      end
    end
    FS.new(fs)
  end

  def Create(this, klass)
    fields_of(this.arg, @schema.classes[this.name])
  end


  def Field(this, klass)
    FS.new({klass.name => {this.name => @typeof.type_of(this.arg, klass, true, :*)}})
  end

  def Regular(this, klass)
    fs = fields_of(this.arg, klass)
    if this.optional then
      this.many ? fs.star(klass.name) : fs.opt(klass.name)
    elsif this.many
      fs.mult(klass.name)
    else
      raise "Invalid regular: #{this}" 
    end
  end
end


def yield_objects(model, &block)
  return if model.nil?
  model.schema_class.fields.each do |fld|
    next if fld.type.Primitive? || !fld.traversal 
    if fld.many then
      model[fld.name].each do |x|
        yield x
        yield_objects(x, &block)
      end
    else
      x = model[fld.name]
      yield x
      yield_objects(x, &block)
    end
  end
end


if __FILE__ == $0 then
  if !ARGV[0] || !ARGV[1] || !ARGV[2] then
    puts "use fieldsof.rb <name>.grammar <name>.schema <rootclass>"
    exit!(1)
  end


  require 'core/system/load/load'
  require 'pp'

  g = Load::load(ARGV[0])
  s = Load::load(ARGV[1])
  start = ARGV[2]

  root_class = s.classes[start]

  to = FieldsOf.new(s)

  yield_objects(g) do |x|
    next if x.nil?
    if x.Create? then
      if s.classes[x.name].nil? then
        puts "WARNING: no class for #{x.name}"
      else
        puts "#{to.fields_of(x, s.classes[x.name])}"
      end
    end
  end

  # puts to.fields_of(g.start, nil)


  # g.rules.each do |rule|
  #   puts "RULE #{rule.name}: #{to.fields_of(rule, nil)}"
  #   rule.arg.alts.each do |alt|
  #     puts "\tALT: #{to.fields_of(alt, nil)}"
  #     if alt.Sequence? then
  #       alt.elements.each do |elt|
  #         puts "\t\tELT: #{to.fields_of(elt, nil)}"
  #       end
  #     end
  #   end
  # end
end

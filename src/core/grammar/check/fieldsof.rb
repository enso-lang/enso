

require 'core/grammar/check/typeof'
require 'core/grammar/check/infer'

class FS
  attr_reader :tbl

  def initialize(tbl = {})
    @tbl = tbl
  end

  def each(&block)
    tbl.each(&block)
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

  def opt
    regularize(:opt)
  end

  def plus
    regularize(:plus)
  end
  
  def star
    regularize(:star)
  end
  
  def regularize(op)
    new_tbl = {}
    tbl.each do |name, tm|
      new_tbl[name] = TM.new(tm.type, tm.mult.send(op))
    end
    FS.new(new_tbl)
  end
  
  private

  def merge(o, op)
    shared = tbl.keys & o.tbl.keys
    new_tbl = {}
    bottom = TM.new(GrammarTypes::VOID, Multiplicity::ZERO)
    shared.each do |k|
      new_tbl[k] = tbl[k].send(op, o.tbl[k])
    end
    (tbl.keys - o.tbl.keys).each do |k|
      new_tbl[k] = tbl[k].send(op, bottom)
    end    
    (o.tbl.keys - tbl.keys).each do |k|
      new_tbl[k] = o.tbl[k].send(op, bottom)
    end
    FS.new(new_tbl)
  end
end


class FieldsOf
  BOT = FS.new

  def initialize(schema, root, typeof = TypeOf.new(schema, root))
    @schema = schema
    @typeof = typeof
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
    if @memo[this]
      return @memo[this]
    end

    @memo[this] = BOT
    x = fields_of(this.rule, klass)
    while x != @memo[this]
      @memo[this] = x
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

  def Code(this, klass)
    ts = Infer.new(@schema).infer(this.expr, klass)
    fs = {}
    ts.each do |fn, t|
      if t.Primitive? then
        fs[fn] = TM.new(GrammarTypes::Primitive.new(t), Multiplicity::ONE)
      elsif t.Class? then
        fs[fn] = TM.new(GrammarTypes::Klass.new(t), Multiplicity::ONE)
      else
        raise "Inconsistent type: #{t}"
      end
    end
    FS.new(fs)
  end

  def Create(this, klass)
    fields_of(this.arg, @schema.classes[this.name])
  end


  def Field(this, klass)
    FS.new({this.name => @typeof.type_of(this.arg, klass, true, :*)})
  end

  def Regular(this, klass)
    fs = fields_of(this.arg, klass)
    if this.optional then
      this.many ? fs.star : fs.opt
    elsif this.many
      fs.plus
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

  to = FieldsOf.new(s, root_class)

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

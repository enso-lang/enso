
require 'core/grammar/code/gfold'
require 'core/grammar/code/types'

class TypeEval < GrammarFold
  include GrammarTypes
  attr_reader :schema

  def initialize(schema)
    super(VOID, VOID)
    @schema = schema
  end
end

class FieldTypeEval < TypeEval
  attr_reader :name

  def initialize(schema, name)
    super(schema)
    @name = name
  end

  def Field(this, _)
    if this.name == name then
      ContribTypeEval.new(schema).eval(this.arg, true)
    else
      VOID
    end
  end
end

class ContribTypeEval < TypeEval
  def Value(this, _);
    # todo: atom
    key = this.kind == 'sym' ? 'str' : this.kind
    Primitive.new(schema.primitives[key])
  end

  def Ref(this, _)
    Klass.new(schema.classes[this.name])
  end

  def Create(this, _)
    Klass.new(schema.classes[this.name])
  end

  def Lit(this, in_field)
    in_field ? schema.primitives['str'] : VOID
  end
end


if __FILE__ == $0 then
  if !ARGV[0] then
    puts "use type-eval.rb <name>.grammar <name>.schema"
    exit!(1)
  end


  require 'core/system/load/load'
  require 'core/grammar/code/reach'
  require 'pp'

  g = Loader.load(ARGV[0])
  s = Loader.load(ARGV[1])

  # Perform reachability analysis:
  # obtain a table from Create's to
  # a set of fields.
  r = Reach.new
  r.reach(g.start, [])
  tbl = r.tbl

  tbl.each do |cr, fs|
    fs.each do |f|
      te = FieldTypeEval.new(s, f)
      t = te.eval(cr.arg, false)
      puts "#{cr.name}.#{f}: #{t}"
    end
  end
  
end

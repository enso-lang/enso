
require 'core/grammar/code/gfold'
require 'core/grammar/code/types'
require 'core/grammar/code/deref-type'

# TODO: produces error messages when things are not found in schema.

class TypeEval < GrammarFold
  include GrammarTypes

  def initialize(schema, root_class, ctx)
    super(:+, :*, VOID, VOID)
    @schema = schema
    @root_class = root_class
    @ctx = ctx # owner class of field we're computing the type for
  end

  def Value(this, _);
    key = this.kind == 'sym' ? 'str' : this.kind
    Primitive.new(@schema.primitives[key])
  end

  def Ref(this, _)
    Klass.new(@schema.classes[this.name])
  end

  def Ref2(this, _)
    Klass.new(DerefType.deref(@schema, @root_class, @ctx, this.path))
  end

  def Create(this, _)
    Klass.new(@schema.classes[this.name])
  end

  def Lit(this, in_field)
    in_field ? Primitive.new(@schema.primitives['str']) : VOID
  end
end


if __FILE__ == $0 then
  if !ARGV[0] || !ARGV[1] || !ARGV[2] then
    puts "use type-eval.rb <name>.grammar <name>.schema <rootclass>"
    exit!(1)
  end


  require 'core/system/load/load'
  require 'core/grammar/code/reach-eval'
  require 'core/grammar/code/combine'
  require 'pp'

  g = Loader.load(ARGV[0])
  s = Loader.load(ARGV[1])
  start = ARGV[2]

  tbl = ReachEval.reachable_fields(g)

  root_class = s.classes[start]

  result = combine(tbl, GrammarTypes::VOID) do |cr, f|
    te = TypeEval.new(s, root_class, s.classes[cr.name])
    te.eval(f.arg, true)
  end
  
  result.each do |c, fs|
    fs.each do |f, m|
      puts "#{c}.#{f}: #{m}"
    end
  end
end

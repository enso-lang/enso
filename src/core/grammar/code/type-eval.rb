
require 'core/grammar/code/gfold'
require 'core/grammar/code/types'

class TypeEval < GrammarFold
  include GrammarTypes
  attr_reader :schema

  def initialize(schema)
    super(VOID, VOID)
    @schema = schema
  end

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
    in_field ? Primitive.new(schema.primitives['str']) : VOID
  end
end


if __FILE__ == $0 then
  if !ARGV[0] || !ARGV[1] then
    puts "use type-eval.rb <name>.grammar <name>.schema"
    exit!(1)
  end


  require 'core/system/load/load'
  require 'core/grammar/code/reach'
  require 'core/grammar/code/combine'
  require 'pp'

  g = Loader.load(ARGV[0])
  s = Loader.load(ARGV[1])

  tbl = ReachEval.reachable_fields(g)

  te = TypeEval.new(s)

  result = combine(tbl, GrammarTypes::VOID) do |_, f|
    te.eval(f.arg, true)
  end
  
  result.each do |c, fs|
    fs.each do |f, m|
      puts "#{c}.#{f}: #{m}"
    end
  end
end

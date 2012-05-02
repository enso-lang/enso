
require 'core/grammar/check/multiplicity'
require 'core/grammar/check/gfold'

class MultEval < GrammarFold
  include Multiplicity

  def initialize
    super(:+, :*, ONE, ZERO)
  end

  def Regular(this, in_field)
    m = eval(this.arg, in_field)
    if this.optional then
      this.many ? m.star : m.opt
    elsif this.many
      m.plus
    else
      raise "Invalid regular: #{this}" 
    end
  end
end

# This is an essential in-between step, that is different from type-eval.
# because the field in the grammar may itself be optional (it does not have
# to be the *argument* of the field that might be optional, many etc.).
# In contrast, the type of a field is always derived from symbols below the
# argument of a field (including the argument symbol itself).
# Example: supers in schema.schema; if we start at the field arguments, supers
# gets multiplicity + but is optional because it derives through an optional.
class FieldMultEval < MultEval

  # This is the reason for having the separate super class MultEval
  class Contrib < MultEval
    def Value(this, _); ONE end
    def Ref(this, _); ONE end
    def Create(this, _); ONE end
    def Lit(this, in_field); in_field ? ONE : ZERO end
  end

  def initialize(field)
    super()
    @field = field
    @contrib = Contrib.new
  end

  def Field(this, _)
    # name-based eq. because we have take all field occurrences
    # into account.
    if this.name == @field.name then
      @contrib.eval(this.arg, true)
    else
      ZERO
    end
  end
end

if __FILE__ == $0 then
  if !ARGV[0] then
    puts "use mult-eval.rb <name>.grammar"
    exit!(1)
  end


  require 'core/system/load/load'
  require 'core/grammar/check/reach-eval'
  require 'core/grammar/check/combine'
  require 'pp'
  require 'set'

  g = Loader.load(ARGV[0])

  # Perform reachability analysis:
  # obtain a table from Create's to
  # a set of fields.
  tbl = ReachEval.reachable_fields(g)


  result = combine(tbl, Multiplicity::ZERO) do |cr, f|
    FieldMultEval.new(f).eval(cr.arg, false)
  end

  result.each do |c, fs|
    fs.each do |f, m|
      puts "#{c}.#{f}: #{m}"
    end
  end

end

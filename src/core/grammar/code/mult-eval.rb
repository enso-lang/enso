
require 'core/grammar/code/multiplicity'
require 'core/grammar/code/gfold'

class MultEval < GrammarFold
  include Multiplicity

  def initialize
    super(ONE, ZERO)
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
class FieldMultEval < MultEval

  # This is the reason for having the super class MultEval
  class Contrib < MultEval
    def Value(this, _); ONE end
    def Ref(this, _); ONE end
    def Create(this, _); ONE end
    def Lit(this, in_field); in_field ? ONE : ZERO end
  end

  def initialize(name)
    super()
    @name = name
    @contrib = Contrib.new
  end

  def Field(this, _)
    if this.name == @name then
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
  require 'core/grammar/code/reach'
  require 'core/grammar/code/combine'
  require 'pp'
  require 'set'

  g = Loader.load(ARGV[0])

  # Perform reachability analysis:
  # obtain a table from Create's to
  # a set of fields.
  tbl = ReachEval.reachable_fields(g)


  result = combine(tbl, Multiplicity::ZERO) do |cr, f|
    FieldMultEval.new(f.name).eval(cr.arg, false)
  end

  result.each do |c, fs|
    fs.each do |f, m|
      puts "#{c}.#{f}: #{m}"
    end
  end

  

#   # Obtain the set of classes represented
#   # by the set of Creates in the table.
#   classes = tbl.keys.map do |cr|
#     cr.name
#   end.uniq

#   # Union all fields referenced in tbl for
#   # each class.
#   fields = {}
#   classes.each do |cl|
#     fields[cl] ||= Set.new
#     tbl.each do |cr, fs|
#       if cr.name == cl then
#         fields[cl] |= fs
#       end
#     end
#   end

#   # If one of the fields for a class C does
#   # not occur in *all* Creates representing C
#   # then the multiplicity is seeded with ZERO.
#   # (In other words, absence in tbl means there
#   # is a path through the grammar where the field
#   # never occurs. If it does occur once in another path
#   # += will make the multiplicity optional)

#   result = {}
#   classes.each do |cl|
#     result[cl] ||= {}
#     fields[cl].each do |f|
#       tbl.each do |cr, fs|
#         if cr.name == cl then
#           if fs.include?(f)  then
#             meval = FieldMultEval.new(f.name)
#             m = meval.eval(cr.arg, false)
#             if result[cl][f.name] then
#               result[cl][f.name] += m
#             else
#               result[cl][f.name] = m
#             end
#           elsif !result[cl][f.name]
#             result[cl][f.name] = Multiplicity::ZERO
#           end
#         end
#       end
#     end
#   end

#   tbl.each do |cr, fs|
#     fs.each do |f|
#       meval = FieldMultEval.new(f.name)
#       m = meval.eval(cr.arg, false)
#       puts "#{cr.name}.#{f.name}: #{m}"
#     end
#   end
  
end

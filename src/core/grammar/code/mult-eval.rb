
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
    else
      raise "Invalid regular: #{this}" if !this.many
      m.plus
    end
  end
end

class FieldMultEval < MultEval
  def initialize(name)
    super()
    @name = name
  end

  def Field(this, _)
    if this.name == @name then
      ContribMulEval.new.eval(this.arg, true)
    else
      ZERO
    end
  end
end


class ContribMulEval < MultEval
  def Value(this, _); ONE end
  def Ref(this, _); ONE end
  def Create(this, _); ONE end
  def Lit(this, in_field); in_field ? ONE : ZERO end
end

if __FILE__ == $0 then
  if !ARGV[0] then
    puts "use mult-eval.rb <name>.grammar"
    exit!(1)
  end


  require 'core/system/load/load'
  require 'core/grammar/code/reach'
  require 'pp'

  g = Loader.load(ARGV[0])

  # Perform reachability analysis:
  # obtain a table from Create's to
  # a set of fields.
  r = Reach.new
  r.reach(g.start, [])
  tbl = r.tbl

  
  # Obtain the set of classes represented
  # by the set of Creates in the table.
  classes = tbl.keys.map do |cr|
    cr.name
  end.uniq

  # Union all fields referenced in tbl for
  # each class.
  fields = {}
  classes.each do |cl|
    fields[cl] ||= []
    tbl.each do |cr, fs|
      if cr.name == cl then
        fields[cl] |= fs
      end
    end
  end

  # If one of the fields for a class C does
  # not occur in *all* Creates representing C
  # then the multiplicity is seeded with ZERO.
  # (In other words, absence in tbl means there
  # is a path through the grammar where the field
  # never occurs.)

  result = {}
  classes.each do |cl|
    result[cl] ||= {}
    fields[cl].each do |f|
      tbl.each do |cr, fs|
        if cr.name == cl then
          if fs.include?(f)  then
            meval = FieldMultEval.new(f)
            m = meval.eval(cr.arg, false)
            if result[cl][f] then
              result[cl][f] += m
            else
              result[cl][f] = m
            end
          elsif !result[cl][f]
            result[cl][f] = Multiplicity::ZERO
          end
        end
      end
    end
  end

  tbl.each do |cr, fs|
    fs.each do |f|
      meval = FieldMultEval.new(f)
      m = meval.eval(cr.arg, false)
      puts "#{cr.name}.#{f}: #{m}"
    end
  end

  pp result
end

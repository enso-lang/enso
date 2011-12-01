
require 'core/grammar/code/multiplicity'

class MultEval
  include Multiplicity

  def initialize
    @memo = {}
  end

  def mult(this, in_field)
    #puts "Mult: #{this} (in_field = #{in_field})"
    if respond_to?(this.schema_class.name) then
      send(this.schema_class.name, this, in_field)
    else
      ZERO
    end
  end

  def Rule(this, in_field)
    mult(this.arg, in_field)
  end


  def Call(this, in_field)
    if @memo[this]
      return @memo[this]
    end
    @memo[this] = BOTTOM
    x = mult(this.rule, in_field)
    while x != @memo[this]
      @memo[this] = x
      x = mult(this.rule, in_field)
    end
    return x
  end

  def Sequence(this, in_field)
    if this.elements.length == 1 then
      mult(this.elements[0], in_field)
    else
      this.elements.inject(ZERO) do |cur, elt|
        cur * mult(elt, false)
      end
    end
  end

  def Alt(this, in_field)
    # NB: alts is never empty
    x = mult(this.alts[0], in_field)
    this.alts[1..-1].inject(x) do |cur, alt|
      cur + mult(alt, in_field)
    end
  end

  def Regular(this, in_field)
    m = mult(this.arg, in_field)
    if this.optional then
      this.many ? m.star : m.opt
    else
      raise "Invalid regular: #{this}" if !this.many
      m.plus
    end
  end

  def Field(this, _)
    mult(this.arg, true)
  end
end

class FieldMultEval < MultEval
  def initialize(name)
    super() # why are the () needed here????
    @name = name
  end

  def Field(this, _)
    if this.name == @name then
      ContribMulEval.new.mult(this.arg, true)
    else
      ZERO
    end
  end
end


class ContribMulEval < MultEval
  def Value(this, _); ONE end
  def Ref(this, _); ONE end
  def Create(this, _); ONE end

  def Lit(this, in_field)
    in_field ? ONE : ZERO
  end

end

=begin

 X ::= arg:Y
 Y ::= [C] ...
    | "(" Y ")"

gives + for arg because
"(" and ")" count as contributors.

so we pass in_field boolean
across |, set to false in sequence.
(this is also what implode does, btw)


    # we now get results for each individual occurence
    # of a create. Per class created, the multiplicities
    # should be pairwise added e.g.
    
Regular.arg: 1
Regular.arg: 1
Regular.arg: 1
Regular.arg: 1
Regular.sep: 1
Regular.arg: 1
Regular.sep: 1

sep should be optional because it does not occur for all
creates. So absence there, means 0

=end

if __FILE__ == $0 then
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

  
  # Convert the
  classes = tbl.keys.map do |cr|
    cr.name
  end.uniq

  fields = {}
  classes.each do |cl|
    fields[cl] ||= []
    tbl.each do |cr, fs|
      if cr.name == cl then
        fields[cl] |= fs
      end
    end
  end

  result = {}
  classes.each do |cl|
    result[cl] ||= {}
    fields[cl].each do |f|
      tbl.each do |cr, fs|
        if cr.name == cl then
          if fs.include?(f)  then
            meval = FieldMultEval.new(f)
            m = meval.mult(cr.arg, false)
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

#   tbl.each do |cr, fs|
#     fs.each do |f|
#       meval = FieldMultEval.new(f)
#       m = meval.mult(cr.arg, false)
#       puts "#{cr.name}.#{f}: #{m}"
#     end
#   end

  pp result
end

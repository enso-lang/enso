
require 'core/system/load/load'

class Reach
  attr_reader :tbl
  
  def initialize
    @memo = {}
    @tbl = {}
  end

  def reach(this, accu)
    send(this.schema_class.name, this, accu)
  end

  def Sequence(this, accu)
    this.elements.each do |elt|
      reach(elt, accu)
    end
  end

  def Call(this, accu)
    if !@memo[this] then
      @memo[this] = []
      reach(this.rule, accu2 = [])
      @memo[this] = accu2
    end
    @memo[this].each do |x|
      accu << x
    end
  end

  def Rule(this, accu)
    reach(this.arg, accu)
  end

  def Create(this, _)
    reach(this.arg, accu = [])
    # creates for the same class can occur multiple times
    # hence | and uniq
    @tbl[this] ||= []
    @tbl[this] |= accu.uniq
  end

  def Field(this, accu)
    accu << this.name
    reach(this.arg, [])
  end

  def Alt(this, accu)
    this.alts.each do |alt|
      reach(alt, accu)
    end
  end

  def Lit(this, accu)
  end

  def Ref(this, accu)
  end

  def Value(this, accu)
  end

  def Code(this, accu)
  end

  def Regular(this, accu)
    reach(this.arg, accu)
  end

end


if __FILE__ == $0 then
  require 'pp'
  g = Loader.load(ARGV[0])
  r = Reach.new
  r.reach(g.start, [])
  pp r.tbl
end

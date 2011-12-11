
require 'core/grammar/check/gfold'
require 'set'

class ReachEval < GrammarFold
  attr_reader :tbl

  EMPTY = Set.new

  def initialize
    super(:|, :|, EMPTY, EMPTY) 
  end

  def Create(this, in_field)
    eval(this.arg, false)
  end

  def Field(this, in_field)
    eval(this.arg, true)
    Set.new([this])
  end
end


if __FILE__ == $0 then
  require 'core/system/load/load'
  require 'pp'
  g = Loader.load(ARGV[0])
  tbl = ReachEval.reachable_fields(g)
  tbl.each do |cr, fs|
    puts "#{cr.name}: #{fs.inspect}"
  end
end

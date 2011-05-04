

require 'cyclicmap'
require 'grammar/cpsparser'

# TODO: refactor not to use instance var @output

class Unparse < CyclicCollect 
  attr_reader :output

  def initialize(grammar, output)
    super()
    @literals = CPSParser::CollectKeywords.run(grammar)
    @output = output
  end

  def self.unparse(grammar, pt, output = '')
    unp = self.new(grammar, output)
    unp.recurse(pt)
    return unp.output
  end

  def escape(this)
    # TODO: for sym a.b.c check only on a
    if this.kind == "sym" && @literals.include?(this.value) then
      "\\#{this.value}"
    else
      this.value
    end
  end

  def ParseTree(this)
    @output << this.layout
    recurse(this.top)
  end

  def Sequence(this)
    this.elements.each do |arg|
      recurse(arg)
    end
  end

  def Create(this)
    recurse(this.arg)
  end

  def Field(this)
    recurse(this.arg)
  end

  def Code(this)
  end

  def Value(this)
    @output << escape(this)
    @output << this.layout
  end

  def Lit(this)
    @output << this.value
    @output << this.layout
  end

  def Ref(this)
    # todo: escaping for sym
    @output << this.name
    @output << this.layout
  end

  def Regular(this)
    this.args.each do |arg|
      recurse(arg)
    end
  end 

end



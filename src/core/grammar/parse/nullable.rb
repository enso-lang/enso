

class Nullable
  attr_reader :memo
  def initialize
    @memo = {}
  end

  def nullable?(this)
    if @memo[this].nil? then
      @memo[this] = false
      x = send(this.schema_class.name, this)
      while x != @memo[this] do
        @memo[this] = x 
        x = send(this.schema_class.name, this)
      end
    end
    @memo[this]
  end

  
  def Rule(this)
    nullable?(this.arg)
  end

  def Sequence(this)
    this.elements.inject(true) do |cur, elt|
      cur & nullable?(elt)
    end
  end

  def Alt(this)
    this.alts.inject(false) do |cur, alt|
      cur | nullable?(alt)
    end
  end

  def Call(this)
    nullable?(this.rule)
  end

  def Rule(this)
    nullable?(this.arg)
  end

  def Create(this)
    nullable?(this.arg)
  end
  
  def Field(this)
    nullable?(this.arg)
  end

  def Value(this)
    false
  end

  def Lit(this)
    false
  end

  def Ref(this)
    false
  end

  def Code(this)
    true
  end

  def Regular(this)
    this.optional | nullable?(this.arg)
  end

end


if __FILE__ == $0 then
  require 'core/system/load/load'
  gg = Loader.load('grammar.grammar')
  null = Nullable.new
  puts null.nullable?(gg.start)
  puts null.memo
end

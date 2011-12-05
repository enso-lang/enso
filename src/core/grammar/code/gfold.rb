

class GrammarFold
  def initialize(bottom, unit)
    @memo = {}
    @bottom = bottom
    @unit = unit
  end

  def eval(this, in_field)
    if respond_to?(this.schema_class.name) then
      send(this.schema_class.name, this, in_field)
    else
      @unit
    end
  end

  def Rule(this, in_field)
    eval(this.arg, in_field)
  end

  def Call(this, in_field)
    if @memo[this]
      return @memo[this]
    end

    @memo[this] = @bottom
    x = eval(this.rule, in_field)
    while x != @memo[this]
      @memo[this] = x
      x = eval(this.rule, in_field)
    end
    return x
  end

  def Sequence(this, in_field)
    if this.elements.length == 1 then
      eval(this.elements[0], in_field)
    else
      this.elements.inject(@unit) do |cur, elt|
        cur * eval(elt, false)
      end
    end
  end

  def Alt(this, in_field)
    # NB: alts is never empty
    x = eval(this.alts[0], in_field)
    this.alts[1..-1].inject(x) do |cur, alt|
      cur + eval(alt, in_field)
    end
  end

  def Regular(this, in_field)
    eval(this.arg, in_field)
  end

  def Field(this, _)
    eval(this.arg, true)
  end
end



class GrammarFold
  def initialize(join, meet, bottom, unit_of_meet)
    @join = join  # +
    @meet = meet  # *
    @memo = {}
    @bottom = bottom
    @unit_of_meet = unit_of_meet
  end

  def eval(this, in_field)
    return @unit_of_meet if this.nil?
    if respond_to?(this.schema_class.name) then
      send(this.schema_class.name, this, in_field)
    else
      @unit_of_meet
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
    if this.elements.size == 1 then
      eval(this.elements[0], in_field)
    else
      this.elements.inject(@unit_of_meet) do |cur, elt|
        cur.send(@meet, eval(elt, false))
      end
    end
  end

  def Alt(this, in_field)
    # NB: alts is never empty
    x = eval(this.alts[0], in_field)
    1.upto(this.alts.size - 1) do |i|
      x = x.send(@join, eval(this.alts[i], in_field))
    end
    return x
  end

  def Regular(this, in_field)
    eval(this.arg, in_field)
  end

  def Field(this, _)
    eval(this.arg, true)
  end
end

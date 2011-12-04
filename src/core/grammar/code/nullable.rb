
class Nullable
  def initialize
    @memo = {}
  end

  def nullable?(this)
    if @memo[this] then
      @memo[this]
    else
      @memo[this] = true
      @memo[this] = send(this.schema_class.name, this)
    end
  end

  def Sequence(this)
    this.elements.inject(true) do |cur, elt|
      cur && nullable?(elt)
    end
  end

  def Alt(this)
    # NB: this.alts is never empty
    this.alts.inject(false) do |cur, alt|
      cur || nullable?(alt)
    end
  end


  # Create is essential because it will always
  # produce an object instance, hence non-nullable
  def Create(this) false; end

  def Call(this) nullable?(this.rule); end

  def Rule(this) nullable?(this.arg); end

  def Field(this) nullable?(this.arg); end

  def Code(this) true; end

  def Epsilon(this) true; end

  def Lit(this) this.value == ''; end

  def Value(this) false; end

  def Ref(this) false; end

  def Regular(this) this.optional; end

end

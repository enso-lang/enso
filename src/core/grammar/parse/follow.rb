
require 'set'

class Follow
  attr_reader :memo, :nullable
  def initialize(nullable)
    @memo = {}
    @nullable = nullable
  end

  def follow(this)
    if @memo[this].nil? then
      @memo[this] = Set.new
      x = send(this.schema_class.name, this)
      while x != @memo[this] do
        @memo[this] = x 
        x = send(this.schema_class.name, this)
      end
    end
    @memo[this]
  end

  
  def Rule(this)
    follow(this.arg)
  end

  def Sequence(this)
    all_nullable = true
    s = Set.new
    this.elements.each do |elt|
      if !nullable.nullable?(elt) then
        s |= follow(elt)
        all_nullable = false
        break
      else
        s |= follow(elt) - Set.new([''])
      end
    end
    s << '' if all_nullable
    return s
  end

  def Alt(this)
    this.alts.inject(Set.new) do |cur, alt|
      cur | follow(alt)
    end
  end

  def Call(this)
    follow(this.rule)
  end

  def Rule(this)
    follow(this.arg)
  end

  def Create(this)
    follow(this.arg)
  end
  
  def Field(this)
    follow(this.arg)
  end

  def Value(this)
    Set.new([this.kind.to_sym])
  end

  def Lit(this)
    Set.new([this.value])
  end

  def Ref(this)
    Set.new([:sym])
  end

  def Code(this)
    Set.new
  end

  def Regular(this)
    follow(this.arg)
  end

end


if __FILE__ == $0 then
  require 'core/system/load/load'
  require 'core/grammar/parse/nullable'

  gg = Loader.load('web.grammar')
  null = Nullable.new
  follow = Follow.new(null)
  gg.rules.each do |rule|
    puts "#{rule.name}: #{follow.follow(rule).to_a.map { |x| x.inspect }.join(', ')}"
  end
end

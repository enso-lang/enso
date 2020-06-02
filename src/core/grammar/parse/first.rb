
require 'set'

class First
  attr_reader :memo, :nullable
  def initialize(nullable)
    @memo = {}
    @nullable = nullable
  end

  def first_seq(elts) 
    s = Set.new
    all_nullable = true
    elts.each do |elt|
      f = first(elt)
      if f.include?('') then
        s |= f - Set.new([''])
      else
        all_nullable = false
        s |= first(elt)
        break
      end
    end
    if all_nullable then
      s << ''
    end
    return s
  end

  def first(this)
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
    first(this.arg)
  end

  def Sequence(this)
    all_nullable = true
    s = Set.new
    this.elements.each do |elt|
      if !nullable.nullable?(elt) then
        s |= first(elt)
        all_nullable = false
        break
      else
        s |= first(elt) - Set.new([''])
      end
    end
    s << '' if all_nullable
    return s
  end

  def Alt(this)
    this.alts.inject(Set.new) do |cur, alt|
      cur | first(alt)
    end
  end

  def Call(this)
    first(this.rule)
  end

  def Rule(this)
    first(this.arg)
  end

  def Create(this)
    first(this.arg)
  end
  
  def Field(this)
    first(this.arg)
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
    first(this.arg)
  end

end


if __FILE__ == $0 then
  require 'core/system/load/load'
  require 'core/grammar/parse/nullable'

  gg = Load::load(ARGV[0])
  null = Nullable.new
  first = First.new(null)
  gg.rules.each do |rule|
    puts "#{rule.name}: #{first.first(rule).to_a.map { |x| x.inspect }.join(', ')}"
  end

#   gg.rules.each do |rule|
#     rule.arg.alts.each do |alt|
#       if alt.is_a?("Create") then
#         seq = alt.arg.elements
#       else
#         seq = alt.elements
#       end
#       puts "#{rule.name}: #{first.first_seq(seq).to_a.map { |x| x.inspect }.join(', ')}"
#     end
#   end

end

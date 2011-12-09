
require 'core/grammar/code/lts'
require 'core/grammar/code/deref-type'

class GrammarLTS

  def initialize(schema, root)
    @memo = {}
    @schema = schema
    @root = root
  end

  def eval(this, state, label)
    send(this.schema_class.name, this, state, label)
  end

  def Rule(this, state, label)
    puts "VIsiting rule: #{this.name}"
    key = this.name + (state || 'nil')
    return @memo[key] if @memo[key]
    @memo[key] = LTS.new
    x = eval(this.arg, state, label)
    while x != @memo[key] do
      @memo[key] = x
      x = eval(this.arg, state, label)
    end
    return x
  end

  def Sequence(this, state, label)
    # special case??
    if this.elements.length == 1 then
      return eval(this.elements[0], state, label)
    end

#     if label && this.elements.length == 0 then
#       return LTS.new(Transition.new(state, label, 'EMPTY'))
#     end

    ltss = this.elements.map do |elt|
      eval(elt, state, nil)
    end
    lts = LTS.new
    ltss.permutation do |perm|
      lts += perm.inject(LTS.new) do |cur, elt|
        cur.compose(elt)
      end
    end
    ltss.inject(lts) do |cur, elt|
      cur + elt
    end
  end

  def Alt(this, state, label)
    this.alts.inject(LTS.new) do |cur, alt|
      cur + eval(alt, state, label)
    end
#     ltss = this.alts.map do |alt|
#       eval(alt, state, label)
#     end
#     puts "Alt: #{this}"
#     result = LTS.new
#     outer_join(ltss, state, label) do |xs|
#       puts xs.join(', ')
#       xs.each do |x|
#         result.transitions << x
#       end
#     end
#     return result
    # need to do some kind of generalized outer join here
    # which produces EMPTY transitions if no f-transition
    # could be found in any of the joined ltss
  end

  def outer_join(ltss, c, f, stub = nil)
    all = ltss.inject(LTS.new) { |cur, lts| cur + lts }.transitions
    all.select { |x| x.from == c && x.label == f }.each do |x|
      row = ltss.map do |lts|
        lts.transitions.include?(x) ? x : Transition.new(x.from, x.label, 'EMPTY')
      end
      yield row
    end
  end

  def Call(this, state, label)
    eval(this.rule, state, label)
  end

  def Create(this, state, label)
    puts "CREATE: #{this.name}"
    lts = eval(this.arg, this.name, nil)
    if label then
      lts += LTS.new(Transition.new(state, label, this.name))
    end
    return lts
  end

  def Field(this, state, _)
    eval(this.arg, state, this.name)
  end

  def Regular(this, state, label)
    return eval(this.arg, state, label)

    if this.optional && this.many then
      eval(this.arg, state, label).star(state, label)
    elsif this.many
      eval(this.arg, state, label).plus(state, label)
    else
      eval(this.arg, state, label).opt(state, label)
    end
  end

  def Value(this, state, label)
    #puts "Value: #{this.kind}"
    LTS.new(Transition.new(state, label, this.kind))
  end

  def Ref(this, state, label)
    LTS.new(Transition.new(state, label, this.name))
  end

  def Ref2(this, state, label)
    t = DerefType.deref(@schema, @root, @schema.classes[state], this.path)
    LTS.new(Transition.new(state, label, t.name))
  end

  def Lit(this, state, label)
    #puts "LIT: #{this.value}"
    if label then # means in_field
      LTS.new(Transition.new(state, label, this.value.inspect))
    else
      LTS.new
    end
  end

  def Code(this, state, label)
    LTS.new
  end
end


if __FILE__ == $0 then
  require 'core/system/load/load'

  g = Loader.load(ARGV[0])
  s = Loader.load(ARGV[1])
  root = s.classes[ARGV[2]]

  glts = GrammarLTS.new(s, root)

  lts = glts.eval(g.start, nil, nil)
  lts.transitions.each do |tr|
    puts tr
  end

  File.open('lts.dot', 'w') do |f|
    lts.to_dot(f)
  end
end


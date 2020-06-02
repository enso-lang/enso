
require 'core/grammar/check/lts'

class SchemaLTS

  def initialize
    @memo = {}
  end

  def eval(this, state, label)
    send(this.schema_class.name, this, state, label)
  end

  def Class(this, state, label)
    if @memo[this] then
      return @memo[this]
    end
    if label then
      @memo[this] = LTS.new(Transition.new(state, label, this)) 
      # also make edges to subclasses
      #this.subclasses.each do |c|
      #  @memo[this].transitions << Transition.new(state, label, c)
      #end
    else
      @memo[this] = LTS.new
    end
    this.fields.each do |f|
      if !f.computed && !f.type.is_a?("Primitive") then
        @memo[this] += eval(f, this, nil) 
      end
    end
    this.subclasses.each do |c|
     @memo[this].transitions << Transition.new(this, "", c) #eval(c, nil, nil)
    end
    return @memo[this]
  end

  def Primitive(this, state, label)
    LTS.new
    #LTS.new(Transition.new(state, label, this)) +
    #  LTS.new(Transition.new(this, "", this))
  end

  def Field(this, state, _)
    lts = eval(this.type, state, this.name)
    if this.optional
      lts += lts.opt(state, this.name)
    end
    if this.many then
      lts += lts.plus(state, this.name)
    end
    return lts
  end

end


if __FILE__ == $0 then
  require 'core/system/load/load'

  s = Load::load(ARGV[0])
  r = s.classes[ARGV[1]]
  slts = SchemaLTS.new

  lts = slts.eval(r, nil, nil)
  lts.transitions.each do |tr|
    puts tr
  end

  File.open('schema-lts.dot', 'w') do |f|
    lts.to_dot(f)
  end
end


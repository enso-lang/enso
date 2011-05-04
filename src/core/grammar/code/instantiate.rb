
class Instantiate

  def initialize(factory)
    super()
    @factory = factory
    @defs = {}
    @fixes = []
    @nested_fixes = []
  end

  def run(pt)
    # ugh: @root is set in recurse...
    recurse(pt, nil, nil, 0)
    # currently only nested refs one level deep are supported (e.g. x.y) 
    # in order to support more levels fixes could be a list of lists
    # for each level
    @fixes.each do |fix|
      fix.apply(@defs)
    end
    @nested_fixes.each do |fix|
      fix.apply(@defs)
    end
    return @root
  end

  def recurse(this, *args)
    send(this.schema_class.name, this, *args)
  end

  def update(owner, field, pos, x)
    if field && field.many then
      #puts "UPDATE #{owner} #{field.name} #{x} #{owner.class} #{owner[field.name].class}"
      owner[field.name] << x
      return pos + 1
    elsif field then
      #put "FIELD: #{field.name}"
      owner[field.name] = x
    end

    return pos
  end
      
  def convert(this)
    v = this.value
    case this.kind 
    when "str" then 
      v.gsub(/\\"/, '"')[1..-2]
    when "sqstr" then
      v.gsub(/\\'/, "'")[1..-2]
    when "bool" then
      v == "true"
    when "int" then
      Integer(v)
    when "real" then
      Float(v)
    when "sym" then
      v.sub(/^\\/, '')
    else
      raise "Don't know kind #{this.kind}"
    end
  end

  def ParseTree(this, owner, field, pos)
    recurse(this.top, owner, field, pos)
  end

  def Sequence(this, owner, field, pos)
    this.elements.inject(pos) do |pos1, arg|
      recurse(arg, owner, field, pos1)
    end
  end
  
  def Create(this, owner, field, pos)
    #put "Creating #{this.name}"
    current = @factory.send(this.name)
    # ugly
    @root = current unless owner
    recurse(this.arg, current, nil, 0)
    update(owner, field, pos, current)
  end

  def Field(this, owner, field, pos)
    #puts "Field #{this.name} in #{owner}"
    f = owner.schema_class.fields[this.name]
    recurse(this.arg, owner, f, 0)
  end

  def Code(this, owner, field, pos)
    #put "EXECUTINGC CODE #{this.code} on #{owner}"
    owner.instance_eval(this.code.gsub(/@/, "self."))
  end

  def Value(this, owner, field, pos)
    return pos unless field # values without field????
    #put "Value: #{this} for #{field}"

    if field.key then
      #puts "--------> Defining key #{this} to #{owner}"
      #todo? check this.type == 'sym'?
      @defs[convert(this)] = owner
    end

    update(owner, field, pos, convert(this))
  end

  def Lit(this, owner, field, pos)
    if field && !field.many then
      # don't add literals to lists
      #puts "Parsing Lit #{this.value} for #{field.name}"
      owner[field.name] = this.value
    end
    pos
  end


  def Ref(this, owner, field, pos)
    #puts "Stubbing ref #{this.name} in #{owner}"
    
    #TODO: hack!! to allow undefined symbols to be nil
    return if this.name == "_"
    
    stub = @factory.send(field.type.name)
    if this.name =~ /\./ then
      @nested_fixes << Fix.new(this.name, owner, field, pos)
    else
      @fixes << Fix.new(this.name, owner, field, pos)
    end
    update(owner, field, pos, stub)
  end


  class Fix
    def initialize(name, this, field, pos)
      @name = name
      @this = this
      @field = field
      @pos = pos
    end

    def apply(defs)
      #put "FIXING: #{@name} in #{@this}.#{@field.name}"
      old = @this[@field.name]
      #copy_old_to_actual(old, defs[@name])

      #put "DEFS[@name] = #{defs[@name]}"
      names = @name.split(/\./)
      while !names.empty? do
        n = names.shift
        actual = defs[n]
      end

      if @field.many then
        @this[@field.name][@pos] = defs[actual]
      else
        # code could have been executed on the stub
        # or field have been set, so copy stuff from
        # the stub to the actual thing the ref is resolved to
        copy(@this[@field.name], actual)
        @this[@field.name] = actual
      end
    end
    
    def copy(from, to)
      from.schema_class.fields.each do |f|
        next unless from[f.name]
        if f.many then
          from[f.name].each do |x|
            to[f.name] << x
          end
        else
          to[f.name] = from[f.name]
        end
      end
    end
  end
end



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
    return pos if field.nil?
    if field.many then
      #puts "UPDATE #{owner} #{field.name} #{x} #{owner.class} #{owner[field.name].class}"
      owner[field.name] << x
      return pos + 1
    else
      #puts "FIELD: #{owner}.#{field.name}=#{x}"
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

  def Instances(this, owner, field, pos)
    this.instances.each do |inst|
      recurse(inst, owner, field, pos)
    end
  end

  def List(this, owner, field, pos)
    this.elements.inject(pos) do |pos1, arg|
      recurse(arg, owner, field, pos1)
    end
  end
  
  def Instance(this, owner, field, pos)
    #put "Creating #{this.name}"
    # TODO: @factory[this.type] does not assign default vals.
    current = @factory.send(this.type)
    @root = current unless owner
    this.contents.each do |cnt|
      recurse(cnt, current, nil, 0)
    end
    update(owner, field, pos, current)
  end

  def Field(this, owner, field, pos)
    #puts "Field #{this.name} in #{owner}"
    f = owner.schema_class.fields[this.name]
    recurse(this.value, owner, f, 0)
  end

  def Code(this, owner, field, pos)
    #puts "EXECUTINGC CODE #{this.code} on #{owner}"
    owner.instance_eval(this.code.gsub(/@/, "self."))
  end

  def Prim(this, owner, field, pos)
    return pos unless field # values without field????
    #put "Value: #{this} for #{field}"

    if field.key then
      @defs[convert(this)] = owner
    end

    update(owner, field, pos, convert(this))
  end

  def Ref(this, owner, field, pos)
    #TODO: hack!! to allow undefined symbols to be nil
    return if this.name == "_"
    
    if this.name =~ /\./ then
      @nested_fixes << Fix.new(this.name, owner, field, pos)
    else
      @fixes << Fix.new(this.name, owner, field, pos)
    end
    if field.many && !SchemaSchema.key(field.type)
      # only insert a stub if it is a many-valued collection with no key
      update(owner, field, pos, nil)
    end
  end


  class Fix
    # name is the key in the Ref from the grammar
    # this is the object containing the field whose value is a Ref
    # field is the field name
    # pos is the optional position in a many-valued non-keyed field
    def initialize(name, this, field, pos)
      @name = name
      @this = this
      @field = field
      @pos = pos
    end

    def apply(defs)
      #puts "FIXING: #{@name} in #{@this}.#{@field.name}"

      #put "DEFS[@name] = #{defs[@name]}"
      names = @name.split(/\./)
      while !names.empty? do
        n = names.shift
        actual = defs[n]
      end

      if @field.many then
        @this[@field.name][@pos] = defs[actual]
      else
        @this[@field.name] = actual
      end
    end
  end
end


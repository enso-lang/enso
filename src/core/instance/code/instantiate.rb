
class Instantiate

  # TODO: detect optional literals and coerce to boolean
  
  def initialize(factory)
    super()
    @factory = factory
    @fixes = []
  end

  def self.instantiate(factory, inst)
    self.new(factory).run(inst)
  end
  
  def run(inst)
    # ugh: @root is set in recurse...
    recurse(inst, nil, nil, 0)
    @fixes.each do |fix|
      fix.apply(@root)
    end
    return @root
  end

  def recurse(this, *args)
    #puts "Recursing on #{this}"
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
  
  def convert(this, ftype)
    convert_typed(this.value, this.kind, ftype)
  end

  def convert_typed(v, type, ftype = nil)
    case type
    when "str" then 
      v
    when "bool" then
      v == "true"
    when "int" then
      Integer(v)
    when "real" then
      Float(v)
    when "sym" then
      v
    when "atom" then
      if ftype.nil?
        v   # field type is atom, so allow anything
      else
        convert_typed(v, ftype.name)
      end
    else
      raise "Don't know kind #{type}"
    end
  end

  def Instances(this, owner, field, pos)
    this.instances.each do |inst|
      recurse(inst, owner, field, pos)
    end
  end
  
  def Instance(this, owner, field, pos)
    #puts "Creating #{this.type}"
    # TODO: @factory[this.type] does not assign default vals. [Actually it does now -william]
    current = @factory[this.type]
    @root = current unless owner
    this.contents.each do |cnt|
      recurse(cnt, current, nil, 0)
    end
    update(owner, field, pos, current)
  end

  def Field(this, owner, field, pos)
    #puts "Field #{this.name} in #{owner}"
    #puts "OWN: #{owner.schema_class.fields}"
    f = owner.schema_class.fields[this.name]
    this.values.each do |v|
      recurse(v, owner, f, 0)
    end
  end
  
  def Code(this, owner, field, pos)
    #puts "EXECUTINGC CODE #{this.code} on #{owner}"
    owner.instance_eval(this.code.gsub(/@/, "self."))
  end

  def Prim(this, owner, field, pos)
    return unless field
    #puts "Value: #{this} for #{field}"
    update(owner, field, pos, convert(this, field.type))
  end
  
  def Ref(this, owner, field, pos)
    #puts "THIS: #{this}, field: #{field}, owner = #{owner}"
    @fixes << Fix.new(this.name, owner, field, pos)
    if field.many && !ClassKey(field.type)
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

    def apply(root)
      #puts "FIXING: #{@name} in #{@this}.#{@field.name}"
      actual = Lookup(root, @name)
      raise "Could not find symbol '#{@name}' \nDEFS: #{defs}" if actual.nil?
      if @field.many
        if ClassKey(@field.type)
          @this[@field.name] << actual
        else
          @this[@field.name][@pos] = actual
        end
      else
        #puts "SETTING: #{actual}"
        @this[@field.name] = actual
      end
    end
  end
end


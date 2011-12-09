
class DerefPath
  def self.deref(root, parent, this, path)
    DerefPath.new(root, parent, this).eval(path)
  end

  def initialize(root, parent, this)
    @root = root
    @parent = parent
    @this = this
  end

  def eval(this)
    send(this.schema_class.name, this)
  end

  def Anchor(this)
    #puts "ANCHOR: #{this.type}"
    if this.type == '.' then
      @this
    elsif this.type == '..' then
      @parent
    else
      raise "Invalid anchor: #{this.type}"
    end
  end

  def Sub(this)
    #puts "SUB: #{this.name}"
    ctx = this.parent ? eval(this.parent) : @root
    if this.key then
      #puts "  CTX: #{ctx}"
      #puts "  CTX.#{this.name} = #{ctx[this.name]}"
      ctx[this.name][eval(this.key)]
    else
      ctx[this.name]
    end
  end

  def Const(this)
    #puts "CONST: #{this.value}"
    this.value
  end
end

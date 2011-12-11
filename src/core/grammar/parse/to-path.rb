
require 'core/system/utils/paths'

class ToPath
  include Paths

  def self.to_path(path, it)
    self.new(it).eval(path)
  end

  def initialize(it)
    @it = it
  end

  def eval(this)
    send(this.schema_class.name, this)
  end

  def Anchor(this)
    Path.new([Current.new])
  end
  
  def Sub(this)
    p =  this.parent ? eval(this.parent) : Path.new
    if this.key then
      p.field(this.name).key(eval(this.key))
    else
      p.field(this.name)
    end
  end

  def It(this)
    @it
  end

  def Const(this)
    this.value
  end

end

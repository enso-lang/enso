

class SubstIt

  def self.subst_it(path, it, fact)
    self.new(it, fact).eval(path)
  end

  def initialize(it, fact)
    @it = it
    @fact = fact
  end

  def eval(this)
    send(this.schema_class.name, this)
  end

  def Anchor(this)
    #puts "Subst anchor: #{this.type}"
    @fact.Anchor(this.type)
  end
  
  def Sub(this)
    #puts "Subst sub #{this}"
    p = this.parent && eval(this.parent) 
    k = this.key && eval(this.key)
    @fact.Sub(p, this.name, k)
  end

  def It(this)
    #puts "IT: become #{@it}"
    @fact.Const(@it)
  end

  def Const(this)
    #puts "Subst Const: #{this.value}"
    @fact.Const(this.value)
  end

end

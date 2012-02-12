=begin

Define various types of environment

=end

#inner can take on vastly different values from Hash to MObject
# --thanks to dynamic typing in Ruby
#parent is the super env
class Env
  def initialize(inner={}, parent=nil)
    @parent = parent
    @inner = inner.clone
  end
  def [](var)
    if var_defined?
      @inner[var]
    elsif !@parent.nil?
      @parent[var]
    else
      nil
    end
  end
  def []=(var, val)
    if var_defined?
      @inner[var] = val
    elsif !@parent.nil?
      @parent[var] = val
    else
      nil
    end
  end
  def free?(var)
    self[var].nil?
  end
  def set!(key)
    self[key] = yield self[key]
  end
  def set(key, &block)
    res = self.clone
    res.set!(key, block)
    res
  end

  private

  def var_defined?(var)
    !@inner[var].nil?
  end
end

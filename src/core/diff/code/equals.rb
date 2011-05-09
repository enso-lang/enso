
require 'core/diff/code/diff'

class Equals < Diff::Base
  def initialize()
    super()
  end

  def self.equals(schema, o1, o2)
    self.new.equals(schema, o1, o2)
  end
  
  def equals(schema, o1, o2)
    catch :diff do
      diff(o1, o2)
      return true
    end
    return false 
  end

  def different_single(target, field, old, new)
    throw :diff
  end

  def different_insert(target, field, new)
    throw :diff
  end
  
  def different_delete(target, field, old)
    throw :diff
  end

  def different_modify(target, field, pos, old, new)
    throw :diff
  end
end


require 'set'

class BaseNode
  attr_reader :type, :starts, :ends, :id

  # TODO: remove the global variable
  # cannot resue it for multiple parses
  @@nodes = {}

  def self.nodes
    @@nodes
  end

  def kids
    []
  end

  def self.new(*args)
    @@nodes[args] ||= super(*args)
  end

  def initialize(starts, ends, type)
    @starts = starts
    @ends = ends
    @type = type
    @hash = 29 * self.class.to_s.hash + 37 * starts + 17 * ends
  end

  def hash
    @hash
  end
end

class Empty < BaseNode
  def initialize(pos, type)
    super(pos, pos, type)
  end

  def ==(x)
    return true if x.equal?(self)
    return false unless x.is_a?(Empty)
    return true
  end

end

class Leaf < BaseNode
  attr_reader :value
  attr_reader :ws

  def initialize(starts, ends, type = nil, value = nil, ws = nil)
    super(starts, ends, type)
    #puts "MAKING LEAF: #{value}"
    @value = value
    @ws = ws
    @hash += 13 * value.hash
  end

  def ==(x)
    return true if self.equal?(x)
    return false unless x.is_a?(Leaf)
    super(x) && value == x.value
  end

  def ends
    # TODO: this messes up error messages.
    super + ws.length
  end

  def to_s
    "T('#{value}', ws = '#{ws}')"
  end

end

class Node < BaseNode
  attr_reader :kids

  def self.new(item, z, w)
    if item.dot == 1 && item.elements.length > 1 then
      return w
    end
    t = item
    if item.dot == item.elements.length then
      t = item.expression
    end
    x = w.type
    k = w.starts
    i = w.ends
    if z != nil then
      s = z.type
      j = z.starts
      # assert k == z.ends
      y = super(j, i, t)
      y.add_kid(Pack.new(item, k, z, w))
    else
      y = super(k, i, t)
      y.add_kid(Pack.new(item, k, nil, w))
    end
    return y
  end

   def initialize(starts, ends, type)
    super(starts, ends, type)
    @kids = []
    @hash += 13 * type.hash
  end

  def add_kid(pn)
    return if @kids.include?(pn)
    @kids << pn
  end
  
  def ==(x)
    return true if self.equal?(x)
    return false unless x.is_a?(Node)
    super(x) && type == x.type
  end

end


class Pack
  attr_reader :item, :pivot, :left, :right, :id

  def initialize(item, pivot, left, right)
    @item = item
    @pivot = pivot
    @left = left
    @right = right
  end

  def kids
    [left, right].compact
  end

  def hash
    "pack".hash + 7 * item.hash + 31 * pivot
  end

  def ==(x)
    return true if x.equal?(self)
    return false unless x.is_a?(Pack)
    return item == x.item && pivot == x.pivot
  end

end

    

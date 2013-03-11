
#require 'set'

module SPPF

  class BaseNode
    attr_reader :type, :starts, :ends

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
      if !@@nodes.has_key?(args) then
        @@nodes[args] = super(*args)
      else
        @@nodes[args]
      end
    end

    def initialize(starts, ends, type)
      @starts = starts
      @ends = ends
      @type = type
      @hash = 29 * self.class.to_s.hash + 37 * starts + 17 * ends
    end

    
    def build(owner, accu, field, fixes, paths, fact, orgs)
      type.build_spine(self, owner, accu, field, fixes, paths, fact, orgs)
    end

    def build_kids(owner, accu, field, fixes, paths, fact, orgs)
      raise Ambiguity.new(self) if kids.length > 1
      if !kids.empty? then
        kids.first.build(owner, accu, field, fixes, paths, fact, orgs)
      end
      nil
    end

    def hash
      @hash
    end

    def eql?(o)
      equals(o)
    end

    def origin(orgs)
      path = orgs.path
      offset = orgs.offset(starts)
      length = ends - starts
      start_line = orgs.line(starts)
      start_column = orgs.column(starts)
      end_line = orgs.line(ends)
      end_column = orgs.column(ends)
      Location.new(path, offset, length, start_line, 
                   start_column, end_line, end_column)
    end
  end

  class Empty < BaseNode
    def initialize(pos, type)
      super(pos, pos, type)
    end

    def equals(x)
      if !x.is_a?(Empty)
        false
      else
        true
      end
      #return true if x.equal?(self)
      #return false unless x.is_a?(Empty)
      #return true
    end

    def build(owner, accu, field, fixes, paths, fact, orgs)
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

    def equals(x)
      if !x.is_a?(Leaf)
        false
      else
        value.equals(x.value)
      end
      #return true if self.equal?(x)
      #return false unless x.is_a?(Leaf)
      #super(x) && value == x.value
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
        w
      else
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
        y
      end
    end

    def initialize(starts, ends, type)
      super(starts, ends, type)
      @kids = []
      @hash += 13 * type.hash
    end

    def add_kid(pn)
      includes = false
      @kids.each do |k|
        if k.equals(pn)
          includes = true
        end
      end
      if includes then
        nil
      else
        @kids << pn
      end
    end
    
    def equals(x)
      if !x.is_a?(Node)
        false
      else
        type.equals(x.type)
      end
      #return true if self.equal?(x)
      #return false unless x.is_a?(Node)
      #super(x) && type == x.type
    end

  end


  class Pack
    attr_reader :item, :pivot, :left, :right

    def initialize(item, pivot, left, right)
      @item = item
      @pivot = pivot
      @left = left
      @right = right
    end

    def hash
      "pack".hash + 7 * item.hash + 31 * pivot
    end

    def build(owner, accu, field, fixes, paths, fact, orgs)
      left.build(owner, accu, field, fixes, paths, fact, orgs) if left
      right.build(owner, accu, field, fixes, paths, fact, orgs)
    end

    def equals(x)
      if !x.is_a?(Pack)
        false
      else
        item.equals(x.item) && pivot == x.pivot
      end
      #return true if x.equal?(self)
      #return false unless x.is_a?(Pack)
      #return item == x.item && pivot == x.pivot
    end

    def kids
      if left then
        [left, right]
      else
        [right]
      end
    end
  end

end

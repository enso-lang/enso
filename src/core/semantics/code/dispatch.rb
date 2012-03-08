
module WorkList
  # Maintains a worklist of nodes to work on
  # There is no guarantee that the same node will not be called multiple times
  #  and this behavior is sometimes needed (eg attribute grammars)

  attr_accessor :worklist

  def initialize(*args)
    @worklist = []
    super
  end

  def method_missing(method_sym, *arguments, &block)
    obj = arguments[0]
    args = arguments[1]

    @worklist << obj unless obj.nil? or @worklist.include?(obj)
    if !@working
      @working = true
      while !@worklist.empty?
        super(method_sym, @worklist.pop, args, &block)
      end
      @working = false
    end
  end
end

module Memoize
  # Ensures no node will be called more than once
  # If default is defined, memo of a current node will be set to default or default(node)
  #  depending on whether default is a proc
  #  otherwise it will be set to true
  #  this is to handle cyclic object graphs

  attr_accessor :memo, :default

  def initialize(*args)
    @memo = {}
    super
  end

  def method_missing(method_sym, *arguments, &block)
    obj = arguments[0]
    if !@memo[obj].nil?
      @memo[obj]
    else
      if @default.nil?
        @memo[obj] = true
      elsif @default.is_a? Proc
        @memo[obj] = @default.call(*arguments, &block)
      else
        @memo[obj] = @default
      end
      res = super
      @memo[obj] = res
    end
  end
end

module Propagate
  def method_missing(method_sym, *arguments, &block)
    obj = arguments[0]
    args = arguments[1]

    new = super(method_sym, obj, args, &block)
    obj.schema_class.fields.each do |f|
      if !f.type.Primitive?
        if !f.many
          send(method_sym, obj[f.name], args, &block) unless obj[f.name].nil?
        else
          obj[f.name].map{|o|send(method_sym, o, args, &block)}
        end
      end
    end
    new
  end
end

module Map
  include Propagate
  include Memoize
end

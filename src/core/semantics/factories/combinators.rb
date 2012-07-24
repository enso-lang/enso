

=begin

Combinators:
Supplant: add data passing methods to children for non-given classgen methods.
Profile (= count + stats)

=end



module Factory
  def supplies?(cls)
    respond_to?(cls.name)
  end
  
  def lookup(cls, sup)
    if cls == Object then
      sup
    elsif supplies?(cls)
      send(cls.name, lookup(cls.superclass, sup))
    else
      lookup(cls.superclass, sup)
    end
  end

  def to_s
    self.class.name
  end
end

class Combinator
  def initialize(f1, f2)
    @f1 = f1
    @f2 = f2
  end

  def supplies?(cls)
    @f1.supplies?(cls) || @f2.supplies?(cls)
  end
end


class Merge < Combinator
  def lookup(cls, sup)
    if @f1.supplies?(cls)
      @f1.lookup(cls, sup)
    else
      @f2.lookup(cls, sup)
    end
  end
end    

class Extend < Combinator
  def lookup(cls, sup)
    @f1.lookup(cls, @f2.lookup(cls, sup))
  end

  def to_s
    "#{@f1} < #{@f2}"
  end
end

class Rename
  def initialize(fact, renaming)
    @fact = fact
    @renaming = renaming
  end

  def supplies?(cls)
    sym = cls.name.to_sym
    if @renaming.has_key?(sym) then
      cls = rename(cls, @renaming[sym])
    end
    @fact.supplies?(cls)
  end

  def lookup(cls, sup)
    if @renaming.has_key?(cls.name.to_sym) then
      rcls = rename(cls, @renaming[cls.name.to_sym])
      x = @fact.lookup(rcls, sup)
      rename(x, cls.name.to_sym)
    else
      @fact.lookup(cls, sup)
    end
  end

  def rename(cls, sym)
    cls = Class.new(cls)
    cls.instance_eval "def name; \"#{sym}\" end"
    return cls
  end
end 

# TODO: also lazy etc.
class Generic
  def supplies?(cls)
    true
  end
end

class Only
  # TODO: probably to restrictive
  # Should be more like extend and passing through super factory
  # if requested class is not in @only.
  def initialize(fact, only)
    @fact = fact
    @only = only
  end

  def supplies?(cls)
    @only.include?(cls.name.to_sym)
  end

  def lookup(cls, sup)
    if @only.include?(cls.name.to_sym)
      @fact.lookup(cls, sup)
    else
      sup
    end
  end
end


class Fixpoint < Generic
  def initialize(inits)
    @inits = inits
  end

  def lookup(cls, sup)
    cls = Class.new(sup)
    @inits.each do |op, seed|
      cls.class_eval %Q{
        def #{op}(*args)
          @memo ||= {}
          @memo[:#{op}] ||= {}
          if @memo[:#{op}].has_key?(self) then
            return @memo[:#{op}][self]
          end
          @memo[:#{op}][self] = prev = #{seed.inspect}
          x = super(*args)
          while x != prev do
            prev = x
            x = super(*args)
            @memo[:#{op}][self] = x
          end
        end
      }
    end
    cls
  end
end


class Memo < Generic
  def initialize(ops)
    @ops = ops
  end

  def lookup(cls, sup)
    cls = Class.new(sup) do
      def initialize
        @memo = {}
      end
    end
    @ops.each do |op|
      cls.class_eval %Q{
        def #{op}(*args, &block)
          @memo[:#{op}] ||= {}
          if @memo[:#{op}].has_key?(args) then
             return @memo[:#{op}][args]
          end
          @memo[:#{op}][args] = super(*args, &block)
        end
      }
    end
    cls
  end
end


class Lazy
  include Factory

  def initialize(op)
    @op = op
  end

  class Delay
    def initialize(args, block_block, &block)
      @args = args
      @block_block = block_block
      @block = block
    end
    
    def method_missing(sym, *args, &block)
      @block.call(*@args, &@block_block).send(sym, *args, &block)
    end
  end

  def Node(sup)
    cls = Class.new(sup)
    cls.send(:define_method, @op) do |*args, &block|
      Delay.new(args, block) do |*args, &block| 
        super(*args, &block) 
      end
    end
    cls
  end
end



class Count < Generic
  def initialize(ops)
    @ops = ops
  end

  def lookup(cls, sup)
    cls = Class.new(sup)
    cls.send(:define_method, :count) do
      @@__count
    end
    cls.send(:define_method, :__incr) do |op|
      @@__count ||= {}
      @@__count[op] ||= 0
      @@__count[op] += 1
    end
    @ops.each do |op|
      cls.class_eval %Q{
        def #{op}(*args, &block)
          __incr(:#{op})
          super(*args, &block)
        end
      }
    end
    cls
  end
end

class Map < Generic
  def initialize(op)
    @op = op
  end

  def lookup(cls, sup)
    cls = Class.new(sup)
    cls.send(:define_method, @op) do |*args, &block|
      inits = super(*args, &block)
      self.class.new(*inits)
    end
    cls
  end
end



# class Tuple < Generic
#   def initialize(op1, op2, op)
#     @op1 = op1
#     @op2 = op2
#     @op = op
#   end

#   def lookup(cls, sup)
#     cls = Class.new(sup)
#     cls.class_eval %Q{
#       def #{@op}(*args, &block)
#         x = #{@op1}(*args, &block)
#         y = #{@op2}(*args, &block)
#         [x, y]
#       end
#       def #{@op1}(*args, &block)
#         @__x = super(*args, &block)
#       end
#       def #{@op2}(*args, &block)
#         @__y = super(*args, &block)
#         [@__x, @__y]
#       end
#     }
      
#   end

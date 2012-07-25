

=begin

Combinators:
Supplant: add data passing methods to children for non-given classgen methods.
Profile (= count + stats)

Some of these combinators can be improved if we have full knowledge of 
the schema structure (hence, in Enso it will be better). For instance when
generically traversing all fields, knowledge of inverses, spine etc.

Note: to implement extension of signatures, tupling, function
composition, allow a class factory to also provide deepest classes for
reference typed fields.

=end

module Operators
  def <(other)
    Extend.new(self, other)
  end

  def +(other)
    Merge.new(self, other)
  end

  def [](syms)
    Only.new(self, syms)
  end
end

module Factory
  include Operators

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
  include Operators
  def lookup(cls, sup)
    if @f1.supplies?(cls)
      @f1.lookup(cls, sup)
    else
      @f2.lookup(cls, sup)
    end
  end
end    

class Extend < Combinator
  include Operators
  def lookup(cls, sup)
    @f1.lookup(cls, @f2.lookup(cls, sup))
  end

  def to_s
    "#{@f1} < #{@f2}"
  end
end

class Only
  include Operators
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
  include Operators
  def supplies?(cls)
    true
  end
end


class Circular < Generic
  # Implementation based on Magnusson, Hedin. Circular Reference
  # Attributed Grammars - their Evaluation and Applications, 2004.

  def initialize(inits)
    @inits = inits
  end

  def lookup(cls, sup)
    cls = Class.new(sup)

    @inits.each do |op, seed|
      org_op = op
      op = op.to_s.sub(/[?!]/, '')
      cls.class_eval %Q{          
        def #{org_op}(*args, &block)
          @computed_#{op} ||= false
          @value_#{op} ||= #{seed}
          @visited_#{op} ||= false

          $in_circle ||= false
          $change ||= false

          if @computed_#{op} then
            return @value_#{op}
          end

          if !$in_circle then
            $in_circle = true
            @visited_#{op} = true
            begin
              $change = false
              new = super(*args, &block)
              if new != @value_#{op} then
                $change = true
              end
              @value_#{op} = new
            end while $change
            @visited_#{op} = false
            @computed_#{op} = true
            $in_circle = false
            return @value_#{op}
          elsif !@visited_#{op} then
            @visited_#{op} = true
            new = super(*args, &block)
            if new != @value_#{op} then
              $change = true
            end
            @value_#{op} = new
            @visited_#{op} = false
            return @value_#{op}
          else
            return @value_#{op}
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

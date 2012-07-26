

=begin

Combinators:
Supplant: add data passing methods to children for non-given classgen methods.
Profile (= count + stats)

Some of these combinators can be improved if we have full knowledge of 
the schema structure (hence, in Enso it will be better). For instance when
generically traversing all fields, knowledge of inverses, spine etc.

Note: to implement extension of signatures, tupling, function
composition, allow a class factory to also provide deepest classes for
reference typed fields. For instance, they can then override eval and
extend it with an env param and calling super without args.

Todo: make a generic aspect that takes a class factory and produces
classes based on the type of a field, but the connectivity of the
graph itself. E.g. lift a SPPF into another SPPF structure where the
nodes are typed according to node.type. This would solve the ugliness
of Item and Epsilon in Parse.

=end

module Operators
  def <(other)
    Extend.new(self, other)
  end

  def +(other)
    Merge.new(self, other)
  end

  def [](syms)
    Restrict.new(self, syms)
  end
end

module Factory
  include Operators

  def supplies?(cls)
    respond_to?(cls.name)
  end
  
  def lookup(cls, sup)
    if cls.respond_to?(:schema_class)
      lookup_schema_class(cls, sup)
    else
      lookup_ruby_class(cls, sup)
    end
  end

  def to_s
    self.class.name
  end

  private

  # TODO: make different factory modules

  def lookup_schema_class(cls, sup)
    if supplies?(cls) then
      send(cls.name, cls.supers.inject(sup) { |sup, c| lookup_schema_class(c, sup) })
    else
      cls.supers.inject(sup) { |sup, c| lookup_schema_class(c, sup) }
    end
  end

  def lookup_ruby_class(cls, sup)
    if cls == Object then
      sup
    elsif supplies?(cls)
      send(cls.name, lookup(cls.superclass, sup))
    else
      lookup(cls.superclass, sup)
    end
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

class Restrict
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

class Traversal < Generic
  def initialize(visit, ops)
    raise "Traversal name #{visit} in #{ops}" if ops.include?(visit)
    @visit = visit
    @ops = ops
  end

  def field_visits(cls)
    #tflds = cls.fields.select { |f| f.traversal }.map { |f| f.name }
    tflds = cls.fields.map { |f| f }
    calls = tflds.map do |f| 
      "if #{f}.is_a?(Array) then 
          #{f}.each { |x| x.#{@visit}(*args, &block) }
       elsif !#{f}.nil?
          #{f}.#{@visit}(*args, &block)
       end"
    end
    calls.join("\n")
  end

  def self_visits
    vs = @ops.map { |o| "#{o} = #{o}(*args)" } +
      ["yield self, #{@ops.join(', ')}"]
    vs.join("\n")
  end
end




class TopDown < Traversal
  def lookup(cls, sup)
    # TODO: deal with graphs instead of trees only
    cls = Class.new(sup)
    cls.class_eval %Q{
      def #{@visit}(*args, &block)
        #{self_visits}
        #{field_visits(cls)}
      end
    }
    cls
  end
end  

class BottomUp < Traversal
  def lookup(cls, sup)
    cls = Class.new(sup)
    cls.class_eval %Q{
      def #{@visit}(*args, &block)
        #{field_visits(cls)}
        #{self_visits}
      end
    }
    cls
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


class Cyclic < Generic
  def initialize(inits)
    @inits = inits
  end

  def lookup(cls, sup)
    cls = Class.new(sup)
    @inits.each do |op, bot|
      cls.class_eval %Q{
        def #{op}(*args, &block)
          @memo_#{op} ||= {}
          if @memo_#{op}.has_key?(args) then
            return @memo_#{op}[args]
          end
          @memo_#{op}[args] = #{bot}
          super(*args, &block)
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
    cls = Class.new(sup)
    @ops.each do |op|
      cls.class_eval %Q{
        def #{op}(*args, &block)
          @memo_#{op} ||= {}
          if @memo_#{op}.has_key?(args) then
            return @memo_#{op}[args]
          end
          @memo_#{op}[args] = super(*args, &block)
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


class Debug < Generic
  def lookup(cls, up)
    
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

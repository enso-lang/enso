

=begin

Combinators:
Supplant: add data passing methods to children for non-given classgen methods.
Profile (= count + stats)

Some of these combinators can be improved if we have full knowledge of 
the schema structure (hence, in Enso it will be better). For instance when
generically traversing all fields, knowledge of inverses, spine etc.

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

# class Visit < Generic
#   # This one needs schema info to work...
#   def initialize(visit, ops)
#     @visit = visit
#     @ops = ops
#   end

#   def lookup(cls, sup)
#     cls = Class.new(sup)
#     calls = @ops.map do |op|
#       "@@tbl[self][:#{op}] = #{op}(*args, &block)"
#     end
#     cls.class_eval %Q{
#       def #{@visit}(*args, &block)
#         @@stack = []
#         @@tbl ||= {}
#         @@tbl[self] ||= {}
#         #{calls}
#         puts "Visiting: \#{self}"
#         self.instance_variables.each do |ivar|
#           next if ivar == :@parent
#           puts "Visiting: \#{ivar}"
#           value = self.instance_variable_get(ivar)
#           unless value.is_a?(String) || value.is_a?(Numeric) ||
#               value.is_a?(TrueClass) || value.is_a?(FalseClass) ||
#               value.is_a?(Symbol) then
#             if value.is_a?(Array) then
#               value.each do |x|
#                 if !@@stack.include?(x) then
#                   @@stack.push(x)
#                   x.#{@visit}(*args, &block)
#                   @@stack.pop
#                 end
#               end
#             else
#               if !@@stack.include?(value) then
#                 @@stack.push(value)
#                 value.#{@visit}(*args, &block)
#                 @@stack.pop
#               end
#             end
#           end
#         end
#         @@tbl
#       end
#     }
#     cls
#   end   
# end


class Circular < Generic
  def initialize(inits)
    @inits = inits
  end

  # TODO: must detect if i'm in a circle or not (a la JastAdd)
  def lookup(cls, sup)
    cls = Class.new(sup)

        # def initialize(*args, &block)
        #   super(*args, &block)
        #   @computed_#{op} = false
        #   @value_#{op} = #{seed}
        #   @visited_#{op} = false
        # end

    @inits.each do |op, seed|
      cls.class_eval %Q{          
        def #{op}(*args, &block)
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


class Fixpoint < Generic
  def initialize(inits)
    @inits = inits
  end

  # TODO: must detect if i'm in a circle or not (a la JastAdd)
  def lookup(cls, sup)
    cls = Class.new(sup)
    @inits.each do |op, seed|
      cls.class_eval %Q{
        def #{op}(*args, &block)
          @memo ||= {}
          @memo[:#{op}] ||= {}
          if @memo[:#{op}].has_key?(self) then
            return @memo[:#{op}][self]
          end
          @memo[:#{op}][self] = prev = #{seed}
          x = super(*args, &block)
          while x != prev do
            prev = x
            @memo[:#{op}][self] = x
            x = super(*args, &block)
          end
          @memo[:#{op}][self]
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



# NB: for schema inference, introduce a Variable type.

module GrammarTypes

  class Type
    def primitive?
      false
    end

    def klass?
      false
    end

    def lub_with_class(c); 
      puts "TYPE (#{self.class}): #{self} with #{c}"
      
      UNDEF
    end
    def lub_with_primitive(p); UNDEF end
    #def lub_with_atom(a); UNDEF end

    def cat_with_class(t);
      puts "CAT type (#{self.class}): #{self} with #{t}"
      UNDEF
    end
    def cat_with_primitive(t); UNDEF end
    #def cat_with_atom(t); UNDEF end

    def <=(t)
      t == self + t
    end
  end

  class Klass < Type
    attr_reader :klass
    
    def initialize(klass)
      #puts "MY KLASS = #{klass.inspect}"
      if klass.nil? then
        raise "BUG: klass argument is nil"
      end
      @klass = klass
    end

    def klass?
      true
    end

    def subclass_of?(x)
      #puts "X = #{x}"
      #puts "X.klass = #{x.klass}"
      #puts "KLASS = #{klass}"
      return true if klass == x.klass
      #p klass.supers
      klass.supers.any? do |sup|
        #puts "SUP = #{sup.inspect}"
        Klass.new(sup).subclass_of?(x)
      end
    end
        
    def lub_with_class(y)
      x = self
      #puts "LUBBING: #{x} with #{y}"
      return x if y == VOID
      return x if x == y
      return y if x.subclass_of?(y)
      return x if y.subclass_of?(x)
      x.klass.supers.each do |sup1|
        y.klass.supers.each do |sup2|
          t = Klass.new(sup1) + Klass.new(sup2)
          return t if t != UNDEF
        end
      end
      return UNDEF
    end

    def +(t); t.lub_with_class(self) end
    def *(t); t.cat_with_class(self) end
    
    def ==(o)
      return false if !o.is_a?(Klass)
      klass == o.klass
    end

    def to_s; klass.name end
  end

  class Primitive < Type
    attr_reader :primitive

    def initialize(primitive)
      @primitive = primitive
    end

    def primitive?
      true
    end

    def lub_with_primitive(p)
      if self == p then
        self
      elsif p == VOID then
        self
      else
        UNDEF
      end
    end

    def cat_with_primitive(p)
      if self == p then
        self
      elsif p == VOID then
        self
      else
        UNDEF
      end
    end

    #def lub_with_atom(a)
    #  a
    #end

    def +(t); t.lub_with_primitive(self) end
    def *(t); t.cat_with_primitive(self) end

    def ==(o)
      return false if !o.is_a?(Primitive)
      primitive == o.primitive
    end

    def to_s; primitive.name end
  end

#   class Atom < Type
#     def initialize
#       super(nil)
#     end

#     def lub_with_primitive(p); self end
#     def lub_with_atom(a); self end

#     def cat_with_primitive(a); self end
#     def cat_with_atom(a); self end

#     def +(t); t.lub_with_atom(self) end
#     def *(t); t.cat_with_atom(self) end
#   end

  class Undef < Type
    def +(t); self end
    def *(t); self end

    def to_s; 'undef' end
  end

  class Void < Type
    def lub_with_class(c); 
      # puts "VOID: #{self} with #{c}"
      c 
    end
    def lub_with_primitive(p); p end
    #def lub_with_atom(a); a end

    def cat_with_class(c); c end
    def cat_with_primitive(p); p end
    #def cat_with_atom(a); a end

    def +(t); t end
    def *(t); t end

    def to_s; 'void' end
  end
  
  VOID = Void.new
  UNDEF = Undef.new
#  ATOM = Atom.new


  def todot(alg, file)
    File.open(file, 'w') do |f|
      f.puts "digraph bla {"
      alg.each do |e1|
        f.puts "n#{e1.object_id} [label=\"#{e1}\"]"
        alg.each do |e2|
          if e1 <= e2 then
            f.puts "n#{e2.object_id} -> n#{e1.object_id} [dir=back]"
          end
        end
      end
      f.puts "}"
    end
  end

end


if __FILE__ == $0 then
  require 'core/system/load/load'
  if !ARGV[0] then
    puts "Usage: types.rb <schema>"
    exit!(1)
  end


  include GrammarTypes
  s = Load::load(ARGV[0])
  ts = s.classes.map do |c|
    Klass.new(c)
  end
  ts += s.primitives.map do |p|
    Primitive.new(p)
  end
  ts += [VOID, UNDEF]
  
  puts "testing comm of +"
  ts.each do |t1|
    ts.each do |t2|
      if t1 + t2 != t2 + t1 then
        puts "lub(#{t1}, #{t2}) = #{t1 + t2}"
        puts " - lub(#{t2}, #{t1}) = #{t2 + t1}"
      end
    end
  end

  puts "testing comm of *"
  ts.each do |t1|
    ts.each do |t2|
      if t1 * t2 != t2 * t1 then
        puts "#{t1} * #{t2} = #{t1 * t2}"
        puts " - #{t2} * #{t1}) = #{t2 * t1}"
      end
    end
  end

  puts "Table for +"
  done = []
  ts.each do |t1|
    ts.each do |t2|
      next if done.include?([t2, t1])
      done << [t1, t2]
      puts "#{t1} + #{t2} = #{t1 + t2}"
    end
  end

  puts "Table for *"
  done = []
  ts.each do |t1|
    ts.each do |t2|
      next if done.include?([t2, t1])
      done << [t1, t2]
      puts "#{t1} * #{t2} = #{t1 * t2}"
    end
  end

#   puts "Table for <="
#   ts.each do |t1|
#     ts.each do |t2|
#       puts "#{t1} <= #{t2} = #{t1 <= t2}"
#     end
#   end
  
  puts "Finding bottom"
  ts.each do |t1|
    yes = true
    ts.each do |t2|
      yes &&= t1 <= t2
    end
    if yes then
      puts "bottom: #{t1}"
    end
  end

  puts "Finding top"
  ts.each do |t1|
    yes = true
    ts.each do |t2|
      yes &&= t2 <= t1
    end
    if yes then
      puts "top: #{t1}"
    end
  end

  todot(ts, 'types.dot')
end

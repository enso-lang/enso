

module GrammarTypes

  class Type

    def lub_with_class(c); UNDEF end
    def lub_with_primitive(p); UNDEF end

    def cat_with_class(t); UNDEF end
    def cat_with_primitive(t); UNDEF end

#     def <=(t)
#       self == self * t
#     end

    def <=(t)
      t == self + t
    end

  end

  class Klass < Type
    attr_reader :klass

    def initialize(klass)
      @klass = klass
    end

    def subclass_of?(x)
      return true if klass == x.klass
      klass.supers.any? do |sup|
        Klass.new(sup).subclass_of?(x)
      end
    end
        
    def lub_with_class(y)
      x = self
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

    def lub_with_primitive(p)
      if self == p then
        self
      else
        UNDEF
      end
    end

    def +(t); t.lub_with_primitive(self) end
    def *(t); t.cat_with_primitive(self) end

    def ==(o)
      return false if !o.is_a?(Primitive)
      primitive == o.primitive
    end

    def to_s; primitive.name end
  end

  class Undef < Type
    def +(t); self end
    def *(t); self end

    def to_s; '1' end
  end

  class Void < Type
    def lub_with_class(c); c end
    def lub_with_primitive(p); p end

    def cat_with_class(c); c end
    def cat_with_primitive(p); p end

    def +(t); t end
    def *(t); t end

    def to_s; '0' end
  end
  
  VOID = Void.new
  UNDEF = Undef.new


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

  include GrammarTypes
  s = Loader.load(ARGV[0])
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

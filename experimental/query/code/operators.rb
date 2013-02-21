

module Operators


  BINOPS = {
    'in' => :member,
    '*' => :times,
    '/' => :div,
    'mod' => :mod,
    'intersect' => :intersect,
    '+' => :add,
    '-' => :sub,
    'union' => :union,
    'except' => :except,
    '||' => :pipe2,
    '==' => :equal,
    '!=' => :not_equal,
    'and' => :conj, # todo shortcutting?
    'or' => :disj
  }

  def member(x, y)
    y.include?(x)
  end

  def times(x, y)
    x * y
  end

  def div(x, y)
    x / y
  end

  def mod(x, y)
    x % y
  end

  def intersect(x, y)
    x.select do |e|
      y.include?(e)
    end
  end

  def add(x, y)
    x + y
  end

  def sub(x, y)
    x - y
  end

  def union(x, y)
    x | y
  end

  def except(x, y)
    x.select do |e|
      !y.include?(e)
    end
  end

  def pipe2(x, y)
    raise "Don't know the meaning of ||"
  end

  def equal(x, y)
    x == y
  end

  def not_equal(x, y)
    x != y
  end

  def conj(x, y)
    x && y
  end

  def disj(x, y)
    x || y
  end

  UNOPS = {
    'not' => :not,
    '-' => :neg,
    '+' => :pos
  }

  def not(x)
    !x
  end

  def neg(x)
    -x
  end

  def pos(x)
    +x
  end



  COMPOPS = {
    '<' => :lt,
    '>' => :gt,
    '<=' => :leq,
    '>=' => :geq
  }

  COMPOPS.each do |op, name|
    module_eval %Q{
      def #{name}(x, y, q)
        return x #{op} y unless q
        send(q, x, y, :#{op})
      end
    }
  end

  def all(x, y, op)
    x.each do |a|
      y.each do |b|
        return false unless a.send(op, b)
      end
    end
    return true
  end

  def any(x, y, op)
    x.each do |a|
      y.each do |b|
        return true if a.send(op, b)
      end
    end
    return false
  end

  alias_method :some, :any

  # Comprehensions

  def for_all(var, coll, body, env)
    env = {}.update(env)
    coll.inject(true) do |cur, x|
      env[var] = x
      cur && eval(body, env)
    end
  end

  def exists(var, coll, body, env)
    env = {}.update(env)
    coll.detect do |x|
      env[var] = x
      eval(body, env)
    end
  end


  

end


require 'rational'

class Vector
  attr_reader :inds, :hash

  def self.make(hash, inds = nil)
    keys = hash.keys
    if inds then
      raise "Keys not in given indices: #{keys}" if keys & inds != keys
      keys = inds
    end
    Vector.new(keys, hash)
  end

  def self.fill(inds, value)
    nh = {}
    inds.each do |k|
      nh[k] = value
    end
    make(nh, inds)
  end

  def initialize(inds, hash)
    @inds = inds.sort
    @hash = hash
  end

  def [](i)
    raise "No such index #{i}" unless inds.include?(i)
    hash[i] || 0
  end

  def []=(i, x)
    raise "No such index: #{i}" unless inds.include?(i)
    hash[i] = x
  end

  def each
    inds.each do |i|
      yield self[i]
    end
  end

  def each_with_index
    inds.each do |i|
      yield self[i], i
    end
  end

  def scale(n)
    raise "Not an integer: #{n}" unless n.is_a?(Numeric)
    nh = {}
    hash.each_key do |k|
      nh[k] = hash[k] * n 
    end
    Vector.new(inds, nh)
  end

  def -(v)
    self + v.scale(-1)
  end

  def +(v)
    ensure_compatible(v)

    nh = {}
    inds.each do |i|
      x = self[i] + v[i]
      nh[i] = x if x != 0
    end
    Vector.new(inds, nh)
  end

  def *(v)
    return scale(v) if v.is_a?(Numeric)
    inner(v)
  end

  def inner(v)
    ensure_compatible(v)
    n = 0
    hash.each_key do |i|
      n += hash[i] * v[i]
    end
    return n
  end

  def /(x)
    return scale(Rational(1, x)) if x.is_a?(Numeric)
    ensure_compatible(x)
    nh = {}
    hash.each_key do |k|
      nh[k] = Rational(hash[k], x[k])
    end
    Vector.new(inds, nh)
  end

  def <(v) # support comparison
    ensure_compatible(v)

    tmp = false
    v.each_with_index do |x, i|
      tmp ||= x != 0 && self[i] == 0
    end
    return tmp unless tmp
    
    tmp = true
    each_with_index do |x, i|
      tmp &&= v[i] != 0 if x != 0 
    end
    return tmp
  end

  def concat(v)
    raise "Not a vector: #{v}" unless v.is_a?(Vector)
    raise "Indices not disjoint" if inds & v.inds != []
    Vector.new(inds | v.inds, hash.merge(v.hash))
  end

  def restrict(is)
    raise "Given inds not in my inds: #{is}" if is & inds != is
    nh = {}
    hash.each_key do |ind|
      nh[ind] = hash[ind] if is.include?(ind)
    end
    Vector.new(is, nh)
  end

  def normalize
    d = hash.values.inject(0) { |cur, n| cur.gcd(n) }
    nh = {}
    inds.each do |i|
      x = self[i]
      nh[i] = x / d if x != 0
    end
    Vector.new(inds, nh)
  end

  def to_s
    lst = inds.map do |i|
      "#{i}: #{self[i]}"
    end
    return "[#{lst.join(', ')}]"
  end
  
  private

  def ensure_compatible(v)
    raise "Not a vector: #{v}" unless v.is_a?(Vector)
    raise "Incompatible indices" unless inds == v.inds
  end


end

if __FILE__ == $0 then
  v1 = Vector.make({a: 3, b: 4}, [:a, :b, :c])
  v2 = Vector.make({d: 3, e: 6, f: 12}, [:d, :e, :f, :g])
  puts v1
  puts v2
  puts v1.concat(v2)
  puts v1 * 43
  puts v2 + v2
  puts v2.normalize
  puts v2 < v2
  puts v2.restrict([:d, :e])

  puts v2 * v2
end

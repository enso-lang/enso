
require 'applications/petrinet/code/vector'

class Row
  attr_reader :key, :vector

  def initialize(key, vector)
    @key = key
    @vector = vector
  end

  def to_s
    "<#{key}: #{vector}>"
  end
end

class Matrix
  attr_reader :row_keys, :col_keys, :hash

  def self.make(hash, row_keys = nil, col_keys = row_keys)
    row_keys = row_keys || hash.keys
    
    b = hash.keys.all? { |x| row_keys.include?(x) }
    raise "Hash contains keys not in row_keys #{hash.keys - row_keys}" unless b
                                                                         
    
    if col_keys.nil? then
      col_keys = []
      hash.values.each do |row|
        row.each_key do |k|
          col_keys << k unless col_keys.include?(k)
        end
      end
    end
    
    nh = {}
    hash.each do |k, row|
      nh[k] = Vector.new(col_keys, row)
    end
    Matrix.new(row_keys, col_keys, nh)
  end

  def self.identity(row_keys, col_keys = row_keys)
    raise "Keys are not square" if row_keys.length != col_keys.length
    hash = {}
    i = 0
    row_keys.each do |r|
      hash[r] = Vector.new(col_keys, {col_keys[i] => 1})
      i += 1
    end
    Matrix.new(row_keys, col_keys, hash)
  end

  def initialize(row_keys, col_keys, hash = {})
    @row_keys = row_keys.sort
    @col_keys = col_keys.sort
    @hash = hash.dup
  end


  def [](r)
    raise "No such row key: #{r}" unless row_keys.include?(r)
    hash[r] || Vector.new(col_keys, {})
  end

  def set!(x, y, value)
    raise "No such row key: #{x}" unless row_keys.include?(x)
    raise "No such column key: #{y}" unless col_keys.include?(y)
    hash[x] ||= Vector.new(col_keys, {})
    hash[x][y] = value
  end

  def column(c)
    raise "No such col key: #{c}" unless col_keys.include?(c)
    nh = {}
    hash.each_key do |k|
      x = hash[k][c]
      nh[k] = x if x != 0
    end
    Vector.new(row_keys, nh)
  end

  def each(&block)
    # sparse
    hash.values.each(&block)
  end

  def each_with_index(&block)
    # sparse
    hash.each do |k, v| 
      yield v, k
    end
  end

  def delete_if
    # sparse
    hash.each_key do |k|
      if yield hash[k] then
        hash.delete(k)
        row_keys.delete(k)
      end
    end
    self
  end

  def extend!(m)
    raise "Not a matrix: #{m}" unless m.is_a?(Matrix)
    raise "Rowkeys not disjoint: #{m.row_keys}" if row_keys & m.row_keys != []
    raise "Col keys of given matrix not the same" if col_keys != m.col_keys

    add_row_keys!(m.row_keys)

    # NB: each_with_index is sparse
    # and each k is not in the old self.row_keys
    matrix.each_with_index do |vec, k|
      hash[k] = vec
    end
  end


  def extend_rows!(rows)
    rks = rows.map { |row| row.key }
    raise "Rowkeys not disjoint: #{rks}" if row_keys & rks != []
    raise "Rowkeys not unique: #{rks}" if rks.uniq.length != rows.length
    add_row_keys!(rks)
    rows.each do |row|
      hash[row.key] = row.vector
    end
  end

  def row_combinations(&block)
    # sparse
    # TODO: make lazy
    rows = []
    hash.each_key do |k|
      rows << Row.new(k, hash[k])
    end
    rows.combination(2, &block)
  end

  def restrict(cols)
    raise "Columns not in col_keys: #{cols}" if col_keys & cols != cols
    nh = {}
    hash.each_key do |k|
      nh[k] = hash[k].restrict(cols)
    end
    Matrix.new(row_keys, cols, nh)
  end


  def scale(n)
    raise "Not an number: #{n}" unless n.is_a?(Numeric)
    nh = {}
    hash.each_key do |k|
      nh[k] = hash[k] * n
    end
    Matrix.new(row_keys, col_keys, nh)
  end

  def times_vector(v)
    raise "Not a vector #{v}" unless v.is_a?(Vector)
    raise "Incompatible vector: #{v}" if col_keys != v.inds
    nh = {}
    hash.each_key do |k|
      nh[k] = hash[k] * v
    end
    Vector.new(row_keys, nh)
  end

  def *(m)
    return scale(m) if m.is_a?(Numeric)
    return times_vector(m) if m.is_a?(Vector)

    raise "Not a matrix #{m}" unless m.is_a?(Matrix)
    raise "Incompatible row/col set" if m.row_keys != col_keys
    
    rh = {}
    row_keys.each do |r|
      ch = {}
      m.col_keys.each do |c|
        x = self[r] * m.column(c)
        ch[c] = x if x != 0
      end
      rh[r] = Vector.new(m.col_keys, ch) unless ch.empty?
    end

    Matrix.new(row_keys, m.col_keys, rh)
  end

  def /(x)
    return scale(Rational(1, x)) if x.is_a?(Numeric)
    return divide_vector(x) if x.is_a?(Vector)
    raise "Not implemented"
  end

  def divide_vector(v)
    raise "Incompatible vector: #{v}" unless v.inds == col_keys
    nh = {}
    hash.each_key do |k|
      nh[k] = hash[k] / v
    end
    Matrix.new(row_keys, col_keys, nh)
  end

  def -(m)
    self + (m * -1)
  end

  def +(m)
    raise "Not a matrix: #{m}" unless m.is_a?(Matrix)
    if m.col_keys != col_keys || m.row_keys != row_keys then
      raise "Incompatible col/row keys #{m}" 
    end
    nh = {}
    row_keys.each do |k|
      v1 = hash[k]
      v2 = m.hash[k]
      if v1 && v2 then
        nh[k] = v1 + v2
      elsif v1 || v2
        nh[k] = v1 || v2
      end
    end
    Matrix.new(row_keys, col_keys, nh)
  end

  def augment(m)
    raise "Not a m: #{m}" unless m.is_a?(Matrix)
    raise "Incompatible row keys" unless row_keys == m.row_keys
    nh = {}
    ck = col_keys
    row_keys.each do |k|
      l = hash[k] #NB: do not use self[k]
      r = m.hash[k] # or m[k], because then l/r may be 0
      if l && r then
        nh[k] = l.concat(r)
      elsif l || r then
        nh[k] = l || r
      end      
      ck |= r.inds if r 
    end
    Matrix.new(row_keys, ck, nh)
  end
  
  def minimal?(x)
    raise "Not a vector: #{x}" unless x.is_a?(Vector)
    # TODO: can this be sparse? Probably not
    hash.values.each do |y|
      return false if y < x
    end
    return true
  end

  def square?
    row_keys.length == col_keys.length
  end

  def to_s
    lst = row_keys.map do |k|
      "#{k}:\n\t#{hash[k] || Vector.make({}, col_keys)}"
    end
    lst.join(",\n")
  end

  class Eqn
    attr_reader :left, :right

    def initialize(m1, m2, row_keys, col_keys)
      @left = m1
      @right = m2
      @row_keys = row_keys
      @col_keys = col_keys
    end


    def eliminate!(item_r, item_c)
      @right = eliminate1(left, right, item_r, item_c)
      @left = eliminate1(left, left, item_r, item_c)
    end

    private 

    def eliminate1(a, b, item_r, item_c)
      mh = {}
      @row_keys.each do |r|
        vh = {}
        @col_keys.each do |c|
          x = yo2(a, r, c, item_r, item_c, b)
          vh[c] = x if x != 0
        end
        mh[r] = Vector.new(@col_keys, vh) unless vh.empty?
      end
      Matrix.new(@row_keys, @col_keys, mh)
    end

    def yo2(m1, r, c, item_r, item_c, m2)
      d1 = m1[item_r][item_c]
      raise "Singular" if d1 == 0
      d2 = m2[r][c]
      return Rational(d2, d1) if r == item_r
      s = Rational(m1[r][item_c], d1)
      return d2 + -s * m2[item_r][c] 
    end

  end

  def identity
    Matrix.identity(row_keys, col_keys)
  end

  def inverse
    raise "Not square" unless square?
    eqn = Eqn.new(self, identity, row_keys, col_keys)
    row_keys.zip(col_keys).each do |x, y|
      eqn.eliminate!(x, y)
    end
    eqn.right
  end

  def closure
    (identity - self).inverse
  end

  def transpose
    m = Matrix.new(col_keys, row_keys)
    hash.each_key do |r|
      v = hash[r]
      if v then
        v.hash.each_key do |c| 
          m.set!(c, r, v.hash[c])
        end
      end
    end
    return m
  end

  private

  def add_row_keys!(keys)
    @row_keys += keys
    @row_keys.sort!
  end

    
end

if __FILE__ == $0 then
  rk = [:a, :b, :c]
  ck = [:e, :f, :g]
  id = Matrix.identity(rk, ck)
  puts id

  ck = [:h, :i, :j]
  id2 = Matrix.identity(rk, ck)
  puts id2

  idid = id.augment(id2)
  #puts idid


  puts idid.restrict(ck)

  # sparse
  example = {
    p1: {t1: -1, t4: 1},
    p2: {t1: 1, t2: -1},
    p3: {t2: 1, t3: -1},
    p4: {t3: 1, t4: -1},
    p5: {t2: -1, t4: 1},
    p6: {t2: 1, t4: -1}
  }

  m = Matrix.make(example)
  puts m

  id_col_keys = m.row_keys.map { |k| "id_#{k}".to_sym }
  id3 = Matrix.identity(m.row_keys, id_col_keys)
  puts id3

  aug = id3.augment(m)

  puts aug

  puts id + id

  puts id.scale(100)

  puts id - id

  puts m.column(:t2)

  a = Matrix.make({
                    x1: {y1: 14, y2: 9, y3: 3},
                    x2: {y1: 2, y2: 11, y3: 15},
                    x3: {y2: 12, y3: 17},
                    x4: {y1: 5, y2: 2, y3: 3}
                  })

  b = Matrix.make({
                    y1: {z1: 12, z2: 25},
                    y2: {z1: 9, z2: 10},
                    y3: {z1: 8, z2: 5}
                  })

  puts "--------- A"
  puts a

  puts "--------- B"
  puts b

  puts "--------- A * B"
  puts a * b

  id = Matrix.identity([:a, :b, :c])
  inv = (id * 10).inverse
  puts inv
  puts inv * (id * 10)


  bomh = {
    taart: {appelgebak: Rational(0.125)},
    appels: {taart: Rational(2)},
    deeg: {taart: Rational(1)},
    suiker: {taart: Rational(0.5)},
    bloem: {deeg: Rational(0.3)},
    boter: {deeg: Rational(0.3)},
    eieren: {deeg: Rational(0.3)},
    koffiebonen: {koffie: Rational(200)}
  }

  keys = [:taart, :appels, :deeg, :bloem, :boter, :eieren, :koffie, :koffiebonen,
          :appelgebak, :suiker]

  bom = Matrix.make(bomh, keys, keys)
  puts "_____BOM"
  puts bom

  puts "------- CLOSURE"
  puts bom.closure

  total = Vector.new(keys, {
                       taart: 70,
                       appelgebak: 500,
                       appels: Rational(1000.9),
                       deeg: Rational(123.3),
                       suiker:  Rational(102.3),
                       bloem: Rational(2340.23),
                       boter: 1000,
                       eieren: Rational(800.9),
                       koffiebonen: Rational(271.37),
                       koffie: 700
                     })

  puts "___TOTAL"
  puts total

  output = Vector.new(keys, {koffie: 600, appelgebak: 400})
  puts "___OUTPUT"
  puts output

  reject = Vector.new(keys, {
    taart: Rational(0.02),
    appelgebak: Rational(0.01),
    appels: Rational(0.05),
    deeg: Rational(0.04),
    suiker: Rational(0.01),
    bloem: Rational(0.02),
    boter: Rational(0.01),
    eieren: Rational(0.01),
    rozijnen: Rational(0.001),
    room: Rational(0.1),
    koffiebonen: Rational(0.08),
    koffie: Rational(0.01)
  })
  puts "___REJECT"
  puts reject

  puts "___SUCCESS"
  success = Vector.fill(keys, 1) - reject
  puts success

  puts "____PREDICTED TOTAL"
  puts (bom / success).closure * (output / success)

  actual_reject = (output + bom * total) / total

  puts "___ACTUAL REJECT"
  puts actual_reject

  x = Matrix.identity(keys)
  x_bom = x - bom
  bom_inv = x_bom.inverse 
  puts "___BOMINV"
  puts bom_inv

  puts "SHOULD BE IDENTITY"
  puts  bom_inv * x_bom

  puts "========== Value cycle example =========="

  vc = {
    t1: {b1: 15, b5: -2, b6: -1},
    t2: {b1: 1, b2: -1},
    t3: {b2: 1, b3: -1},
    t4: {b3: 1, b4: -1},
    t5: {b2: -1, b4: -2, b5: 1},
    t6: {b1: -2, b2: -2, b3: -1, b4: -2, b6: 1}
  }
  m_vc = Matrix.make(vc)

  puts m_vc


  # TODO: use b's here, but vc is always square so is strange
  # should be generic???
  pro_v = Vector.make({
                       b1: 1,
                       b2: 1,
                       b3: 1,
                       b4: 1,
                       b5: 3,
                       b6: 7
                     })

  puts "PRORATION VECTOR"
  puts pro_v

  puts "STATE VECTOR"
  puts m_vc * pro_v



end

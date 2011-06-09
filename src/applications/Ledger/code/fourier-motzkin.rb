


module FourierMotzkin2

  def canonical_vector(vec)
    c = vec.select { |n| n > 0 }.inject(1) { |cur, n| gcd(cur, n) }
    vec.map { |n| n / c }
  end

  def eliminate_column(vectors, column_nr)
    reduce_combinations(vectors, []) do |x, y, *rest|
      alpha = x[column_nr]
      beta = y[column_nr]
      if alpha * beta < 0 then
        [vec_add(scale(x, beta.abs), scale(y, alpha.abs)), *rest]
      else
        rest
      end
    end
  end

  def reduce_combinations(seq, initial, key, start, stop)
    result = initial
    
  end


  def reduce_cons(seq, from, to)
    result = []
    to.downto(from) do |i|
      result << seq[i] + result
    end
  end

  def scale(v, c)
    v.map { |n| c * n }
  end

  def vec_add(v1, v2) 
    v1.zip(v2).map { |x, y| x * y }
  end


end

module FourierMotzkin

  def fourier_motzkin(matrix, num_of_vars)
    (num_of_vars - 1).downto(0) do |k|
      matrix = eliminate_column(matrix, k)
    end
    return matrix
  end

  private
  
  def eliminate_column(matrix, k)
    result = []
    matrix.each do |i1| 
      # TODO sorting
      if i1[k] == 0 then
        # NB cannot use slice, it wraps around
        sub = (0..k-1).map { |j| i1[j] } 
        result << [*sub, i1[k+1]]
      end
      matrix.each do |i2|
        if i1[k] > 0 && i2[k] < 0 then
          i1 = normalize(i1)
          i2 = normalize(i2)
          sub = (0..k-1).map { |j| i1[k] * i2[j] - i2[k] * i1[j] }
          result << [*sub, i1[k] * i2[k+1] - i2[k] * i1[k+1]]
        end
      end
    end
    return result
  end

  def normalize(vec)
    d = gcd(vec)
    return vec unless d > 0
    vec.map { |i| i / d }
  end

  def gcd(vec)
    vec.inject(0) do |cur, n|
      gcd2(cur, n)
    end
  end

  def gcd2(a, b)
    a = a.abs
    b = b.abs
    a, b = b % a, a while a > 0
    return b
  end

end


if __FILE__ == $0 then
  include FourierMotzkin
  
  example = [
             [0, -1, -3, -10],
             [0,  0, -1,  -1],
             [-1, 0,  6,  -1],
             [0,  1,  3,  15],
             [0,  0,  1,   3],
             [1,  0, -6,  50]
            ]
  example = [
             [-1, 0,  6,  -1],
             [0,  1,  3,  15], 
             [0,  0,  1,   3],
             [0,  0, -1,  -1],
             [0, -1, -3, -10],
             [1,  0, -6,  50]
            ]

  v = fourier_motzkin(example, 2)
  p v
end

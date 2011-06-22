require 'set'
require 'applications/Ledger/code/matrix'


module FourierMotzkin

  def fourier_motzkin(matrix)
    m = matrix.row_keys
    n = matrix.col_keys
    raise "Col keys not disjoint from row keys #{m}, #{n}" if n & m != []

    result = Matrix.identity(m, m).augment(matrix)
    n.each do |col|
      eliminate!(result, col)
    end
    result.restrict(m)
  end

  def eliminate!(matrix, col)
    rows = combine_rows(matrix, col)
    matrix.extend_rows!(rows)
    # TODO: optimization:
    #matrix.delete_if { |row| !matrix.minimal?(row) }
    matrix.delete_if { |row| row[col] != 0 }
  end
    
  def combine_rows(matrix, col)
    result = []
    matrix.row_combinations do |x, y|
      row = combine(x, y, col)
      result << row if row
    end
    return result
  end

  def combine(r1, r2, col)
    v1 = r1.vector
    v2 = r2.vector
    alpha = v1[col]
    beta = v2[col]
    if alpha * beta < 0 then
      v = v1 * beta.abs + v2 * alpha.abs
      Row.new("#{r1.key}+#{r2.key}".to_sym, v.normalize)
    end
  end

end

if __FILE__ == $0 then
  include FourierMotzkin
 
  # sparse
  example = Matrix.make({
    p1: {t1: -1, t4: 1},
    p2: {t1: 1, t2: -1},
    p3: {t2: 1, t3: -1},
    p4: {t3: 1, t4: -1},
    p5: {t2: -1, t4: 1},
    p6: {t2: 1, t4: -1}
  })

  puts example
  v = fourier_motzkin(example)
  puts "_____RESULT____"
  puts v
end

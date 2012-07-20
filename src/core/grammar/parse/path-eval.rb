

module PathEval
  class Const
    attr_reader :value
  end

  class Path
  end

  class Anchor
    attr_reader :type
  end

  class Sub
    attr_reader :parent, :name, :key
  end
end

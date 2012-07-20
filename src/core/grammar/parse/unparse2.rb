

module SPPFUnparse
  class Node
    attr_reader :kids
    def unparse(out)
      kids.each do |kid|
        kid.unparse(out)
      end
      out
    end
  end

  class Leaf
    attr_reader :text, :ws
    def unparse(out)
      out << text
      out << ws
    end
  end

  class Value < Leaf
    attr_reader :kind
    def unparse(out)
      if kind == 'str' then
        out << "\"#{text}\""
        out << ws
      else
        super(out)
      end
    end
  end
end



class Unparse

  def self.unparse(sppf, out = $stdout)
    Unparse.new.recurse(sppf, out)
    return out
  end

  def recurse(sppf, out)
    type = sppf.type 
    sym = type.schema_class.name
    if respond_to?(sym)
      send(sym, type, sppf, out)
    else
      kids(sppf, out)
    end
  end

  def kids(sppf, out)
    return if sppf.kids.empty?
    pack = sppf.kids.first
    recurse(pack.left, out) if pack.left
    recurse(pack.right, out)
  end

  def Lit(this, sppf, out)
    out << sppf.value
    out << sppf.ws
  end

  def Value(this, sppf, out)
    out << sppf.value
    out << sppf.ws
  end

  def Ref(this, sppf, out)
    out << sppf.value
    out << sppf.ws
  end

end

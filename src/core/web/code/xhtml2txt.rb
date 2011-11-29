
require 'htmlentities'

class XHTML2Text
  def self.render(elt, out = '')
    self.new(out).render(elt)
    return out
  end

  attr_reader :out

  def initialize(out)
    @out = out
    @coder = HTMLEntities.new
  end

  def render(obj, *args)
    send(obj.schema_class.name, obj, *args)
  end

  def Element(this)
    out << "<#{this.tag}"
    this.attrs.each do |attr|
      out << ' '
      render(attr)
    end
    if this.contents.empty? then
      out << ' />'
    else
      out << '>'
      this.contents.each do |cnt|
        render(cnt)
      end
      out << "</#{this.tag}>"
    end
  end
  
  def Attr(this)
    out << "#{this.name}=\""
    render(this.value)
    out << "\""
  end

  def Value(this)
    out << @coder.encode(this.value)
  end
  
  def CharData(this)
    out << @coder.encode(this.data)
  end

  def CDATA(this)
    out << "<![CDATA["
    out << this.data
    out << "]]>"
  end
end

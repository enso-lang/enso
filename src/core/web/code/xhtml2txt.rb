
require 'htmlentities'

class XHTML2Text
  def self.render(elt, out = '')
    self.new.render(elt, out)
    return out
  end

  def initialize
    @coder = HTMLEntities.new
  end

  def render(obj, *args)
    send(obj.schema_class.name, obj, *args)
  end

  def Element(this, out)
    out << "<#{this.tag}"
    this.attrs.each do |attr|
      out << ' '
      render(attr, out)
    end
    if this.contents.empty? then
      out << ' />'
    else
      out << '>'
      this.contents.each do |cnt|
        render(cnt, out)
      end
      out << "</#{this.tag}>"
    end
  end
  
  def Attr(this, out)
    out << "#{this.name}=\""
    render(this.value, out)
    out << "\""
  end

  def Value(this, out)
    out << @coder.encode(this.value)
  end
  
  def CharData(this, out)
    out << @coder.encode(this.data)
  end

  def CDATA(this, out)
    out << "<![CDATA["
    out << this.data
    out << "]]>"
  end
end

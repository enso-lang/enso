
require 'htmlentities'
require 'uri'

class Renderable
  CODER = HTMLEntities.new
end


class Text < Renderable
  def initialize(txt)
    @txt = txt
  end

  def value
    @txt
  end

  def render(out)
    out << CODER.encode(@txt)
  end
end

class Result < Renderable
  attr_reader :value, :path

  def initialize(value, path = nil)
    @value = value
    @path = path
  end
  
  def to_s
    "<#{value}, #{path}>"
  end
  
  def render(out)
    # TODO: factor out in object
    if value.respond_to?(:schema_class) then
      out << CODER.encode(path)
    else
      out << CODER.encode(value)
    end
  end
end

class Applicable < Renderable
  attr_reader :func, :args
  
  def initialize(func, args)
    @func = func
    @args = args
  end
end

class Link < Applicable

  def value
    _render
  end

  def render(out)
    _render(out) do |arg|
      URI.escape(arg.to_s)
    end
  end

  private

  def _render(out = '')
    params = []
    func.formals.each_with_index do |f, i|
      arg = args[i].path || args[i].value
      param = "#{f.name}="
      if block_given? then
        params << param + (yield arg)
      else
        param << arg.to_s
      end
    end
    name = func.name
    if params.empty?
      out << name 
    else
      out << "#{name}?#{params.join('&')}"
    end
    return out
  end

end

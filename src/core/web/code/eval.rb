
require 'htmlentities'
require 'uri'

class EvalWeb
  
  class EvalExp

    def eval(obj, *args)
      send(obj.schema_class.name, obj, *args)
    end
    
    def Link(this, tenv, env)
      # todo: eval
      vs = this.call.args.map do |arg|
        eval(arg, tenv, env)
      end
      params = []
      func = this.call.func
      func.sig.formals.each_with_index do |frm, i|
        params << "#{frm}=#{URI.escape(vs[i])}"
      end
      return "#{func.name}?#{params.join('&')}"
    end
      

  end

  def initialize(web)
    @web = web
    @coder = HTMLEntities.new
  end

  def eval(obj, *args)
    send(obj.schema_class.name, obj, *args)
  end

  def defines?(name)
    f = @web.defs.find do |d|
      d.name == name
    end
  end
  
  def eval_req(name, params, out)
    puts "PARAMS: #{params}"
    f = @web.defs.find do |d|
      d.name == name
    end
    eval(f.body, out)
  end
  
  def Element(this, out)
    out << "<#{this.tag}"
    this.attrs.each_with_index do |attr, i|
      out << ' ' if i > 0
      val = @coder.encode(@exp_eval.eval(attr.exp))
      out << "#{attr.name}=\"#{val}"
    end
    out << ">"
    this.body.each do |stat|
      eval(stat, out)
    end
    out << "</#{this.tag}>"
  end

  def For(this, out)
    
  end

  def If(this, out)
  end

  def Block(this, out)
    this.stats.each do |stat|
      eval(stat, out)
    end
  end

  def Text(this, out)
    out << @coder.encode(this.value)
  end

end

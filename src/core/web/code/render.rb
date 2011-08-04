
require 'core/web/code/base'
require 'core/web/code/renderable'

module Web::Eval
  class Render < Base

    def tag(name, attrs, out)
      out << "<#{name}"
      attrs.each do |k, v|
        out << " #{k}=\"";
        v.render(out)
        out << "\""
      end
      if block_given? then
        out << ">"
        yield
        out << "</#{name}>"
      else
        out << " />"
      end
    end

    def Element(this, env, out, errors)
      attrs = {}
      this.attrs.each do |attr|
        attrs[attr.name] = eval_exp(attr.exp, env, errors)
      end
      tag(this.tag, attrs, out) do
        this.body.each do |stat|
          eval(stat, env, out, errors)
        end
      end
    end

    def Output(this, env, out, errors)
      result = eval_exp(this.exp, env, errors)
      result.render(out)
    end
    
    def Text(this, env, out, errors)
      Text.new(this.value).render(out)
    end    

    def Call(this, env, out, errors)
      func = eval_exp(this.exp, env, errors).value
      if func then
        func.apply(self, this.args, this.block, env, out, errors)
      else
        log.warn("Undefined template function: #{this.name}")
      end
    end

    def Do(this, env, out, errors)
      action = eval_exp(this.call, env, errors)
      cond = this.cond && eval_exp(this.cond, env, errors).value
      action.render(out, cond)
    end

  end
end

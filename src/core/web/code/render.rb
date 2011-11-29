
require 'core/system/load/load'
require 'core/web/code/dispatch'

module Web::Eval
  class Render
    include Dispatch

    attr_reader :expr, :log

    def initialize(expr, log)      
      @expr = expr
      @log = log
      @fact = Factory.new(Loader.load('xml.schema'))
    end

    def For(this, env, out) 
      coll = expr.eval(this.iter, env)
      nenv = env.new
      coll.each_with_index do |v, i|
        nenv[this.var] = v
        nenv[this.index] = Result.new(i) if this.index
        eval(this.body, nenv, out)
      end
    end

    def If(this, env, out)
      if expr.eval(this.cond, env).truthy? then
        eval(this.body, env, out)
      elsif this.else then
        eval(this.else, env, out)
      end
    end
    
    def Let(this, env, out)
      nenv = env.new
      this.decls.each do |assign|
        # NB: we use nenv, so basically let is let*
        nenv[assign.name] = expr.eval(assign.exp, nenv)
      end
      eval(this.body, nenv, out)
    end
    
    def Block(this, env, out)
      this.stats.each do |stat|
        eval(stat, env, out)
      end
    end


    def Element(this, env, out)
      elt = @fact.Element(this.tag)
      out << elt
      this.attrs.each do |attr|
        value = @fact.Value(expr.eval(attr.value, env).render)
        elt.attrs << @fact.Attr(attr.name, value)
      end
      this.contents.each do |stat|
        eval(stat, env, elt.contents)
      end
    end

    def Output(this, env, out)
      out << @fact.CharData(expr.eval(this.exp, env).render)
    end
    
    def Text(this, env, out)
      out << @fact.CharData(this.value)
    end    

    def Call(this, env, out)
      # NB: cannot use Template#invoke here, since
      # the argument expressions are evaluated lazily.
      func = expr.eval(this.exp, env).value
      func.apply(self, this.args, this.block, env, out)
    end

    def Do(this, env, out)
      action = expr.eval(this.call, env)
      cond = this.cond && expr.eval(this.cond, env).value
      name = @fact.Attr('name', @fact.Value(action.render_key(cond)))
      value = @fact.Attr('value', @fact.Value(action.render_args))
      type = @fact.Attr('type', @fact.Value('hidden'))
      out << @fact.Element('input', [name, value, type])
    end

  end
end

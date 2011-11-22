
require 'core/system/load/load'
require 'core/web/code/dispatch'

module Web::Eval
  class Render
    include Dispatch

    attr_reader :expr, :log

    def initialize(expr, log)      
      @expr = expr
      @log = log
      @fact = Factory.new(Loader.load('xhtml-content.schema'))
    end

    def For(this, env, out, errors) 
      coll = expr.eval(this.iter, env, errors)
      nenv = env.new
      coll.each_with_index do |v, i|
        nenv[this.var] = v
        nenv[this.index] = Result.new(i) if this.index
        eval(this.body, nenv, out, errors)
      end
    end

    def If(this, env, out, errors)
      if expr.eval(this.cond, env, errors).truthy? then
        eval(this.body, env, out, errors)
      elsif this.else then
        eval(this.else, env, out, errors)
      end
    end
    
    def Let(this, env, out, errors)
      nenv = env.new
      this.decls.each do |assign|
        # NB: we use nenv, so basically let is let*
        nenv[assign.name] = expr.eval(assign.exp, nenv, errors)
      end
      eval(this.body, nenv, out, errors)
    end
    
    def Block(this, env, out, errors)
      this.stats.each do |stat|
        eval(stat, env, out, errors)
      end
    end


    def Element(this, env, out, errors)
      elt = @fact.Element(this.tag)
      this.attrs.each do |attr|
        value = @fact.Value(expr.eval(attr.exp, env, errors).render)
        elt.attrs << @fact.Attr(attr.name, value)
      end
      this.body.each do |stat|
        eval(stat, env, elt.contents, errors)
      end
      out << elt
    end

    def Output(this, env, out, errors)
      puts "OUTPUTING: #{this}"
      out << @fact.CharData(expr.eval(this.exp, env, errors).render)
    end
    
    def Text(this, env, out, errors)
      puts "LITERAL text: #{this.value}"
      out << @fact.CharData(this.value)
    end    

    def Call(this, env, out, errors)
      # TODO: put apply in Template < Callable?
      func = expr.eval(this.exp, env, errors).value
      func.apply(self, this.args, this.block, env, out, errors)
    end

    def Do(this, env, out, errors)
      action = expr.eval(this.call, env, errors)
      cond = this.cond && expr.eval(this.cond, env, errors).value
      name = @fact.Attr('name', @fact.Value(action.render_key(cond)))
      value = @fact.Attr('value', @fact.Value(action.render_args))
      type = @fact.Attr('type', @fact.Value('hidden'))
      out << @fact.Element('input', [name, value, type])
    end

  end
end

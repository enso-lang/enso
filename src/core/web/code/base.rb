
require 'core/web/code/dispatch'

module Web::Eval
  class Base
    include Dispatch
    attr_reader :log

    def initialize(expr, log)      
      @expr = expr
      @log = log
    end

    def eval_exp(exp, env, errors)
      @expr.eval(exp, env, errors)
    end

    def For(this, env, out, errors) 
      r = eval_exp(this.iter, env, errors)
      nenv = {}.update(env)
      coll = r.value
      coll.each_with_index do |v, i|
        if coll.is_a?(Array) # literal list expression
          # or list resulting from cons calls
          # NB: the list contains Result objects.
          nenv[this.var] = Result.new(v.value, v.path)
        else
          # TODO: add each_with_index to ManyField
          key_field = ClassKey(v.schema_class)
          key = key_field ? v[key_field.name] : i
          nenv[this.var] = Result.new(v, r.path.descend_collection(key))
        end
        nenv[this.index] = Result.new(i) if this.index
        eval(this.body, nenv, out, errors)
      end
    end

    def If(this, env, out, errors)
      r = eval_exp(this.cond, env, errors)
      if r.value then
        eval(this.body, env, out, errors)
      elsif this.else then
        eval(this.else, env, out, errors)
      end
    end
    
    def Let(this, env, out, errors)
      nenv = {}.update(env)
      this.decls.each do |assign|
        log.debug "Evaling assignment to: #{assign.name}"
        # NB: use nenv, so basically let is let*
        nenv[assign.name] = eval_exp(assign.exp, nenv, errors)
      end
      eval(this.body, nenv, out, errors)
    end
    
    def Block(this, env, out, errors)
      this.stats.each do |stat|
        eval(stat, env, out, errors)
      end
    end
    
  end
end

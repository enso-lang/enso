
require 'apps/web/code/web'

module Web::Eval

  class BaseClosure
    def initialize(env, abs)
      @env = env
      @abs = abs
    end

    def formals
      @abs.formals
    end

    def tail
      @abs.tail
    end

    def with_args(eval, args, block, call_env)

      # TODO: this can be much simpler as soon as the syntax
      # is fixed.

      # Bind arguments in clean environment derived
      # form this closures lexical environment.
      env = @env.new

      # but conses in an env between call_env
      inter_env = call_env.new

      i = 0
      bind_tail = true
      formals.each do |frm|
        if frm.cons then
          bind_tail = false
          target = []
          env[frm.name] = List.new(target)
          
          # Bind a closure that will update the current
          # formal parameter when the block (if any) is executed.
          inter_env[frm.cons.name] = Result.new(ConsClosure.new(env, 
                                                                frm.cons,
                                                                target))
        else
          # A normal expression is just evaluated and put in the env.
          r = eval.expr.eval(args[i], call_env)
          env[frm.name] = r
          i += 1
        end
      end

      if block then
        if bind_tail && tail
          # bind the block as a closure to name of tail
          env[tail.name] = Result.new(Closure.new(call_env, tail, block))
        elsif !bind_tail
          # run the constructor block to fill in the rest of env
          eval.eval(block, inter_env, [])
        else
          raise "Error: block given but no tail or cons formals"
        end
      end

      yield env
    end
  end

  class Closure < BaseClosure
    attr_reader :body

    def initialize(env, abs, body)
      super(env, abs)
      @body = body
    end

    def apply(eval, args, block, call_env, out)
      with_args(eval, args, block, call_env) do |env|
        eval.eval(body, env, out)
      end
    end

    def inspect
      to_s
    end
  end


  class Function < Closure
    def initialize(env, abs)
      super(env, abs, abs.body)
    end

    def name
      @abs.name
    end

    def to_s
      "FUNCTION(#{name}/#{@abs.formals.size})"
    end

    def inspect
      to_s
    end
  end

  class ConsClosure < BaseClosure
    def initialize(env, abs, target)
      super(env, abs)
      @target = target
    end

    def apply(eval, args, block, call_env, out) 
      # add a record to target with fields according to formals
      record = {}
      with_args(eval, args, block, call_env) do |env|
        bound_tail = true
        formals.each do |frm|
          if frm.cons then
            bound_tail = false
          end
          record[frm.name] = env[frm.name]
        end
        if tail && block && bound_tail then
          # block is bound to the name of tail
          # set the closure as value 
          name = tail.name
          record[name] = env[name]
        end
      end
      @target << Record.new(record)
    end

    def inspect
      to_s
    end
  end

end


require 'core/web/code/web'
require 'ostruct'

module Web::Eval
  class RaisingStream
    def initialize(block)
      @block = block
    end

    def <<(s)
      raise "Cannot render in constructor block: #{block._origin}"
    end
  end

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

    def with_args(eval, args, block, call_env, errors)

      # Bind arguments in clean environment
      env = {}.update(@env)

      # but conses in an env between call_env
      inter_env = {}.update(call_env)

      i = 0
      bind_tail = true
      formals.each do |frm|
        if frm.cons then
          bind_tail = false
          target = []
          env[frm.name] = Result.new(target)
          
          puts "Making a cons-closure for #{frm.name}"
          # Bind a closure that will update the current
          # formal parameter when the block (if any) is executed.
          inter_env[frm.cons.name] = Result.new(ConsClosure.new(env, 
                                                                frm.cons,
                                                                target))
        else
          # A normal expression is just evaluated and put in the env.
          r = eval.eval_exp(args[i], call_env, errors)
          puts "Setting normal formal param #{frm.name} to #{r}"
          env[frm.name] = r
          i += 1
        end
      end

      if block then
        if bind_tail && tail
          # bind the block as a closure to name of tail
          puts "Capturing tail block"
          env[tail.name] = Result.new(Closure.new(call_env, tail, block))
        elsif !bind_tail
          puts "Running the block to fill in cons params."
          # run the constructor block to fill in the rest of env
          eval.eval(block, inter_env, RaisingStream.new(block), errors)
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

    def apply(eval, args, block, call_env, out, errors)
      with_args(eval, args, block, call_env, errors) do |env|
        eval.eval(body, env, out, errors)
      end
    end
  end


  class Function < Closure
    def initialize(env, abs)
      super(env, abs, abs.body)
    end

    def name
      @abs.name
    end

    def run(eval, env, out, errors)
      eval.eval(body, env, out, errors)
    end    

  end

  class ConsClosure < BaseClosure
    def initialize(env, abs, target)
      super(env, abs)
      @target = target
    end


    def apply(eval, args, block, call_env, out, errors) 
      # add a record to target with fields according to formals

      puts "Evaluating cons closure"

      record = {}
      with_args(eval, args, block, call_env, errors) do |env|
        bound_tail = true
        formals.each do |frm|
          if frm.cons then
            bound_tail = false
          end
          #puts "SETTTING: #{frm.name} to #{env[frm.name].value}"
          record[frm.name] = env[frm.name].value
        end
        if tail && block && bound_tail then
          # block is bound to the name of tail
          # set the closure as value 
          name = tail.name
          record[name] = env[name].value
        end
      end
      @target << Result.new(record)

      #puts "Added #{record} to target"
    end

  end

end

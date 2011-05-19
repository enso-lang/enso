
require 'ostruct'

class BaseClosure
  def initialize(eval, env, abs)
    @eval = eval
    @env = env
    @abs = abs
  end

  def formals
    @abs.formals
  end

  def tail
    @abs.tail
  end

  def with_args(args, block, outer)

    # Bind arguments in clean environment
    env = {}.update(@env)

    i = 0
    bind_tail = true
    formals.each do |frm|
      if frm.cons then
        bind_tail = false
        target = []
        env[frm.name] = target

        # Bind a closure that will update the current
        # formal parameter when the block (if any) is executed.
        env[frm.cons.name] = Result.new(ConsClosure.new(@eval, env, frm.cons,
                                              target))
      else
        # A normal expression is just evaluated and put in the env.
        #puts "ARGS[#{i}]: #{args[i]}"
        env[frm.name] = @eval.eval_exp(args[i], outer)
        i += 1
      end
    end

    if tail && bind_tail && block then
      # bind the block as a closure to name of tail
      env[tail.name] = Result.new(Closure.new(@eval, outer, tail, block))
    end

    if tail && !bind_tail && block then
      # run the constructor block to fill in the rest of env
      @eval.eval(block, outer)
    end

    yield env
  end
end

class Closure < BaseClosure
  def initialize(eval, env, abs, body)
    super(eval, env, abs)
    @body = body
  end

  def apply(args, block, outer, out)
    with_args(args, block, outer) do |env|
      @eval.eval(@body, env, out)
    end
  end
end


class Function < Closure
  def initialize(eval, env, abs)
    super(eval, env, abs, abs.body)
  end

  def name
    @abs.name
  end

  def run(env, out)
    @eval.eval(@body, env, out)
  end    

end

class ConsClosure < BaseClosure
  def initialize(eval, env, abs, target)
    super(eval, env, abs)
    @target = target
  end


  def apply(args, block, outer, out) 
    # add a record to target with fields according to formals

    record = OpenStruct.new
    with_args(args, block, outer) do |env|
      bound_tail = true
      formals.each do |frm|
        if frm.cons then
          bound_tail = false
        end
        records.send("#{frm.name}=", env[frm.name])
      end
      if tail && block && bound_tail then
        # block is bound to the name of tail
        # set the closure as value 
        name = tail.name
        record.send("#{name}=", Result.new(env[name]))
      end
    end
    @target << record
  end

end
